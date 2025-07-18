const express = require('express');
const { body, validationResult } = require('express-validator');
const Attendance = require('../models/Attendance');
const User = require('../models/User');
const Class = require('../models/Class');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/attendance
// @desc    Get attendance records
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { role, userId } = req.user;
    const { classId, studentId, date, startDate, endDate, status } = req.query;
    
    let query = {};
    
    // Build query based on user role
    if (role === 'student') {
      query.student = userId;
    } else if (role === 'parent') {
      const parent = await User.findById(userId).populate('parentInfo.children');
      const childrenIds = parent.parentInfo.children.map(child => child._id);
      query.student = { $in: childrenIds };
    } else if (role === 'staff') {
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const classIds = staff.staffInfo.classesAssigned.map(cls => cls._id);
      query.class = { $in: classIds };
    } else if (role === 'admin' || role === 'finance') {
      // Can see all attendance records
    }
    
    // Add filters
    if (classId) query.class = classId;
    if (studentId) query.student = studentId;
    if (status) query.status = status;
    
    // Date filters
    if (date) {
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);
      query.date = { $gte: startOfDay, $lte: endOfDay };
    } else if (startDate && endDate) {
      query.date = { 
        $gte: new Date(startDate), 
        $lte: new Date(endDate) 
      };
    }
    
    const attendance = await Attendance.find(query)
      .populate('student', 'firstName lastName studentInfo')
      .populate('class', 'name grade section')
      .populate('markedBy', 'firstName lastName')
      .populate('subjectAttendance.teacher', 'firstName lastName')
      .sort({ date: -1 });
    
    res.json({ attendance });
    
  } catch (error) {
    console.error('Get attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/attendance
// @desc    Mark attendance
// @access  Private (Staff, Admin only)
router.post('/', [
  authMiddleware,
  roleAuth(['staff', 'admin']),
  body('student').isMongoId(),
  body('class').isMongoId(),
  body('date').isISO8601(),
  body('status').isIn(['present', 'absent', 'late', 'excused'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { student, class: classId, date, status, timeIn, timeOut, subjectAttendance, remarks } = req.body;
    const { role, userId } = req.user;
    
    // Check if staff has access to this class
    if (role === 'staff') {
      const staff = await User.findById(userId);
      const assignedClassIds = staff.staffInfo.classesAssigned.map(cls => cls._id.toString());
      
      if (!assignedClassIds.includes(classId)) {
        return res.status(403).json({ message: 'Access denied to this class' });
      }
    }
    
    // Check if student belongs to the class
    const studentUser = await User.findById(student);
    if (!studentUser || studentUser.studentInfo.class.toString() !== classId) {
      return res.status(400).json({ message: 'Student does not belong to this class' });
    }
    
    // Check if attendance already exists for this date
    const attendanceDate = new Date(date);
    attendanceDate.setHours(0, 0, 0, 0);
    
    const existingAttendance = await Attendance.findOne({
      student,
      date: {
        $gte: attendanceDate,
        $lt: new Date(attendanceDate.getTime() + 24 * 60 * 60 * 1000)
      }
    });
    
    if (existingAttendance) {
      // Update existing attendance
      existingAttendance.status = status;
      existingAttendance.timeIn = timeIn;
      existingAttendance.timeOut = timeOut;
      existingAttendance.subjectAttendance = subjectAttendance || existingAttendance.subjectAttendance;
      existingAttendance.remarks = remarks;
      existingAttendance.markedBy = userId;
      
      await existingAttendance.save();
      await existingAttendance.populate('student', 'firstName lastName studentInfo');
      await existingAttendance.populate('class', 'name grade section');
      
      res.json({
        message: 'Attendance updated successfully',
        attendance: existingAttendance
      });
    } else {
      // Create new attendance record
      const attendance = new Attendance({
        student,
        class: classId,
        date: attendanceDate,
        status,
        timeIn,
        timeOut,
        subjectAttendance,
        remarks,
        markedBy: userId
      });
      
      await attendance.save();
      await attendance.populate('student', 'firstName lastName studentInfo');
      await attendance.populate('class', 'name grade section');
      
      res.status(201).json({
        message: 'Attendance marked successfully',
        attendance
      });
    }
    
  } catch (error) {
    console.error('Mark attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/attendance/summary/:studentId
// @desc    Get attendance summary for a student
// @access  Private
router.get('/summary/:studentId', authMiddleware, async (req, res) => {
  try {
    const { studentId } = req.params;
    const { role, userId } = req.user;
    const { academicYear, month } = req.query;
    
    // Check access permissions
    if (role === 'student' && studentId !== userId.toString()) {
      return res.status(403).json({ message: 'Access denied' });
    } else if (role === 'parent') {
      const parent = await User.findById(userId);
      const childrenIds = parent.parentInfo.children.map(child => child._id.toString());
      if (!childrenIds.includes(studentId)) {
        return res.status(403).json({ message: 'Access denied' });
      }
    } else if (role === 'staff') {
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const student = await User.findById(studentId);
      const assignedClassIds = staff.staffInfo.classesAssigned.map(cls => cls._id.toString());
      
      if (!assignedClassIds.includes(student.studentInfo.class.toString())) {
        return res.status(403).json({ message: 'Access denied' });
      }
    }
    
    // Build date filter
    let dateFilter = {};
    if (academicYear) {
      const yearStart = new Date(`${academicYear}-04-01`);
      const yearEnd = new Date(`${parseInt(academicYear) + 1}-03-31`);
      dateFilter = { $gte: yearStart, $lte: yearEnd };
    } else if (month) {
      const monthStart = new Date(month);
      const monthEnd = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0);
      dateFilter = { $gte: monthStart, $lte: monthEnd };
    }
    
    const query = { student: studentId };
    if (Object.keys(dateFilter).length > 0) {
      query.date = dateFilter;
    }
    
    // Get attendance records
    const attendanceRecords = await Attendance.find(query).sort({ date: 1 });
    
    // Calculate summary
    const summary = {
      totalDays: attendanceRecords.length,
      present: attendanceRecords.filter(a => a.status === 'present').length,
      absent: attendanceRecords.filter(a => a.status === 'absent').length,
      late: attendanceRecords.filter(a => a.status === 'late').length,
      excused: attendanceRecords.filter(a => a.status === 'excused').length
    };
    
    summary.attendancePercentage = summary.totalDays > 0 
      ? ((summary.present + summary.late) / summary.totalDays * 100).toFixed(2)
      : 0;
    
    res.json({
      summary,
      records: attendanceRecords
    });
    
  } catch (error) {
    console.error('Get attendance summary error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/attendance/bulk
// @desc    Mark attendance for multiple students
// @access  Private (Staff, Admin only)
router.post('/bulk', [
  authMiddleware,
  roleAuth(['staff', 'admin']),
  body('classId').isMongoId(),
  body('date').isISO8601(),
  body('attendanceData').isArray({ min: 1 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { classId, date, attendanceData } = req.body;
    const { role, userId } = req.user;
    
    // Check if staff has access to this class
    if (role === 'staff') {
      const staff = await User.findById(userId);
      const assignedClassIds = staff.staffInfo.classesAssigned.map(cls => cls._id.toString());
      
      if (!assignedClassIds.includes(classId)) {
        return res.status(403).json({ message: 'Access denied to this class' });
      }
    }
    
    const attendanceDate = new Date(date);
    attendanceDate.setHours(0, 0, 0, 0);
    
    const results = [];
    
    for (const studentData of attendanceData) {
      const { studentId, status, timeIn, timeOut, remarks } = studentData;
      
      try {
        // Check if attendance already exists
        const existingAttendance = await Attendance.findOne({
          student: studentId,
          date: {
            $gte: attendanceDate,
            $lt: new Date(attendanceDate.getTime() + 24 * 60 * 60 * 1000)
          }
        });
        
        if (existingAttendance) {
          // Update existing
          existingAttendance.status = status;
          existingAttendance.timeIn = timeIn;
          existingAttendance.timeOut = timeOut;
          existingAttendance.remarks = remarks;
          existingAttendance.markedBy = userId;
          
          await existingAttendance.save();
          results.push({ studentId, status: 'updated', attendance: existingAttendance });
        } else {
          // Create new
          const attendance = new Attendance({
            student: studentId,
            class: classId,
            date: attendanceDate,
            status,
            timeIn,
            timeOut,
            remarks,
            markedBy: userId
          });
          
          await attendance.save();
          results.push({ studentId, status: 'created', attendance });
        }
      } catch (error) {
        results.push({ studentId, status: 'error', error: error.message });
      }
    }
    
    res.json({
      message: 'Bulk attendance processed',
      results,
      summary: {
        total: attendanceData.length,
        created: results.filter(r => r.status === 'created').length,
        updated: results.filter(r => r.status === 'updated').length,
        errors: results.filter(r => r.status === 'error').length
      }
    });
    
  } catch (error) {
    console.error('Bulk attendance error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
