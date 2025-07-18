const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Class = require('../models/Class');
const Fee = require('../models/Fee');
const Attendance = require('../models/Attendance');
const { authMiddleware, roleAuth, studentAccessAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/students
// @desc    Get students based on user role
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { role, userId } = req.user;
    const { classId, search, page = 1, limit = 20 } = req.query;
    
    let query = { role: 'student', isActive: true };
    let students = [];
    
    if (role === 'admin' || role === 'finance') {
      // Admin and finance can see all students
      if (classId) query['studentInfo.class'] = classId;
      if (search) {
        query.$or = [
          { firstName: { $regex: search, $options: 'i' } },
          { lastName: { $regex: search, $options: 'i' } },
          { 'studentInfo.studentId': { $regex: search, $options: 'i' } }
        ];
      }
      
      students = await User.find(query)
        .populate('studentInfo.class', 'name grade section')
        .populate('studentInfo.parentId', 'firstName lastName phoneNumber')
        .select('-password')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ firstName: 1, lastName: 1 });
        
    } else if (role === 'staff') {
      // Staff can only see students in their assigned classes
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const classIds = staff.staffInfo.classesAssigned.map(cls => cls._id);
      
      query['studentInfo.class'] = { $in: classIds };
      if (classId && classIds.includes(classId)) {
        query['studentInfo.class'] = classId;
      }
      
      students = await User.find(query)
        .populate('studentInfo.class', 'name grade section')
        .populate('studentInfo.parentId', 'firstName lastName phoneNumber')
        .select('-password')
        .limit(limit * 1)
        .skip((page - 1) * limit)
        .sort({ firstName: 1, lastName: 1 });
        
    } else if (role === 'parent') {
      // Parents can only see their own children
      const parent = await User.findById(userId).populate('parentInfo.children');
      students = parent.parentInfo.children;
      
    } else {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const total = students.length;
    
    res.json({
      students,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / limit),
        total
      }
    });
    
  } catch (error) {
    console.error('Get students error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/students/:id
// @desc    Get student profile
// @access  Private
router.get('/:id', authMiddleware, studentAccessAuth, async (req, res) => {
  try {
    const student = await User.findById(req.params.id)
      .populate('studentInfo.class', 'name grade section classTeacher')
      .populate('studentInfo.parentId', 'firstName lastName phoneNumber email parentInfo.address')
      .select('-password');
    
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    // Get additional student data
    const [fees, recentAttendance] = await Promise.all([
      Fee.find({ student: student._id })
        .sort({ createdAt: -1 })
        .limit(5),
      Attendance.find({ student: student._id })
        .sort({ date: -1 })
        .limit(10)
    ]);
    
    res.json({
      student,
      fees,
      recentAttendance
    });
    
  } catch (error) {
    console.error('Get student profile error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/students
// @desc    Create new student
// @access  Private (Admin only)
router.post('/', [
  authMiddleware,
  roleAuth(['admin']),
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('firstName').trim().isLength({ min: 1 }),
  body('lastName').trim().isLength({ min: 1 }),
  body('phoneNumber').trim().isLength({ min: 10 }),
  body('studentInfo.studentId').trim().isLength({ min: 1 }),
  body('studentInfo.class').isMongoId(),
  body('studentInfo.rollNumber').trim().isLength({ min: 1 }),
  body('studentInfo.parentId').isMongoId()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { email, password, firstName, lastName, phoneNumber, studentInfo } = req.body;
    
    // Check if email already exists
    let existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }
    
    // Check if student ID already exists
    existingUser = await User.findOne({ 'studentInfo.studentId': studentInfo.studentId });
    if (existingUser) {
      return res.status(400).json({ message: 'Student ID already exists' });
    }
    
    // Verify class and parent exist
    const [classExists, parentExists] = await Promise.all([
      Class.findById(studentInfo.class),
      User.findOne({ _id: studentInfo.parentId, role: 'parent' })
    ]);
    
    if (!classExists) {
      return res.status(400).json({ message: 'Class not found' });
    }
    if (!parentExists) {
      return res.status(400).json({ message: 'Parent not found' });
    }
    
    // Create student
    const student = new User({
      email,
      password,
      firstName,
      lastName,
      phoneNumber,
      role: 'student',
      studentInfo: {
        ...studentInfo,
        admissionDate: studentInfo.admissionDate || new Date()
      }
    });
    
    await student.save();
    
    // Add student to parent's children list
    await User.findByIdAndUpdate(
      studentInfo.parentId,
      { $push: { 'parentInfo.children': student._id } }
    );
    
    // Add student to class
    await Class.findByIdAndUpdate(
      studentInfo.class,
      { $push: { students: student._id } }
    );
    
    const populatedStudent = await User.findById(student._id)
      .populate('studentInfo.class', 'name grade section')
      .populate('studentInfo.parentId', 'firstName lastName phoneNumber')
      .select('-password');
    
    res.status(201).json({
      message: 'Student created successfully',
      student: populatedStudent
    });
    
  } catch (error) {
    console.error('Create student error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/students/:id
// @desc    Update student profile
// @access  Private (Admin only)
router.put('/:id', [
  authMiddleware,
  roleAuth(['admin']),
  body('email').optional().isEmail().normalizeEmail(),
  body('firstName').optional().trim().isLength({ min: 1 }),
  body('lastName').optional().trim().isLength({ min: 1 })
], async (req, res) => {
  try {
    const student = await User.findById(req.params.id);
    
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    const updates = { ...req.body };
    delete updates.password; // Don't allow password update through this route
    delete updates.role; // Don't allow role change
    
    Object.assign(student, updates);
    await student.save();
    
    const updatedStudent = await User.findById(student._id)
      .populate('studentInfo.class', 'name grade section')
      .populate('studentInfo.parentId', 'firstName lastName phoneNumber')
      .select('-password');
    
    res.json({
      message: 'Student updated successfully',
      student: updatedStudent
    });
    
  } catch (error) {
    console.error('Update student error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/students/:id/fees
// @desc    Get student's fee records
// @access  Private
router.get('/:id/fees', authMiddleware, studentAccessAuth, async (req, res) => {
  try {
    const { academicYear, status } = req.query;
    
    let query = { student: req.params.id };
    if (academicYear) query.academicYear = academicYear;
    if (status) query.overallStatus = status;
    
    const fees = await Fee.find(query)
      .populate('paymentHistory.receivedBy', 'firstName lastName')
      .sort({ createdAt: -1 });
    
    res.json({ fees });
    
  } catch (error) {
    console.error('Get student fees error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/students/:id/attendance
// @desc    Get student's attendance records
// @access  Private
router.get('/:id/attendance', authMiddleware, studentAccessAuth, async (req, res) => {
  try {
    const { startDate, endDate, status } = req.query;
    
    let query = { student: req.params.id };
    
    if (startDate && endDate) {
      query.date = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    if (status) query.status = status;
    
    const attendance = await Attendance.find(query)
      .populate('markedBy', 'firstName lastName')
      .populate('class', 'name grade section')
      .sort({ date: -1 });
    
    // Calculate attendance statistics
    const totalDays = attendance.length;
    const presentDays = attendance.filter(record => record.status === 'present').length;
    const absentDays = attendance.filter(record => record.status === 'absent').length;
    const lateDays = attendance.filter(record => record.status === 'late').length;
    const attendancePercentage = totalDays > 0 ? ((presentDays + lateDays) / totalDays * 100).toFixed(2) : 0;
    
    res.json({
      attendance,
      statistics: {
        totalDays,
        presentDays,
        absentDays,
        lateDays,
        attendancePercentage
      }
    });
    
  } catch (error) {
    console.error('Get student attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
