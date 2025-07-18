const express = require('express');
const { body, validationResult } = require('express-validator');
const Timetable = require('../models/Timetable');
const Class = require('../models/Class');
const User = require('../models/User');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/timetables
// @desc    Get timetables based on user role
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { role, userId } = req.user;
    const { classId, academicYear, date } = req.query;
    
    let query = { status: 'published', isActive: true };
    
    if (academicYear) query.academicYear = academicYear;
    
    if (role === 'admin' || role === 'finance') {
      // Admin and finance can see all timetables
      if (classId) query.class = classId;
      
    } else if (role === 'staff') {
      // Staff can see timetables for their assigned classes
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const classIds = staff.staffInfo.classesAssigned.map(cls => cls._id);
      
      if (classId && classIds.includes(classId)) {
        query.class = classId;
      } else {
        query.class = { $in: classIds };
      }
      
    } else if (role === 'student') {
      // Students can see their class timetable
      const student = await User.findById(userId);
      query.class = student.studentInfo.class;
      
    } else if (role === 'parent') {
      // Parents can see their children's class timetables
      const parent = await User.findById(userId).populate('parentInfo.children');
      const classIds = parent.parentInfo.children.map(child => child.studentInfo?.class).filter(Boolean);
      query.class = { $in: classIds };
    }
    
    const timetables = await Timetable.find(query)
      .populate('class', 'name grade section')
      .populate('schedule.monday.teacher', 'firstName lastName')
      .populate('schedule.tuesday.teacher', 'firstName lastName')
      .populate('schedule.wednesday.teacher', 'firstName lastName')
      .populate('schedule.thursday.teacher', 'firstName lastName')
      .populate('schedule.friday.teacher', 'firstName lastName')
      .populate('schedule.saturday.teacher', 'firstName lastName')
      .sort({ academicYear: -1, createdAt: -1 });
    
    // If date is provided, get schedule for that specific date
    if (date && timetables.length > 0) {
      const targetDate = new Date(date);
      const scheduleData = timetables.map(timetable => ({
        class: timetable.class,
        schedule: timetable.getScheduleForDate(targetDate)
      }));
      
      return res.json({ schedules: scheduleData, date: targetDate });
    }
    
    res.json({ timetables });
    
  } catch (error) {
    console.error('Get timetables error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/timetables/teacher/:teacherId
// @desc    Get teacher's schedule
// @access  Private
router.get('/teacher/:teacherId', authMiddleware, async (req, res) => {
  try {
    const { teacherId } = req.params;
    const { date } = req.query;
    
    // Check if user can access this teacher's schedule
    if (req.user.role !== 'admin' && req.user.userId !== teacherId) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const targetDate = date ? new Date(date) : new Date();
    const schedule = await Timetable.getTeacherSchedule(teacherId, targetDate);
    
    res.json({ 
      teacher: teacherId,
      date: targetDate,
      schedule 
    });
    
  } catch (error) {
    console.error('Get teacher schedule error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/timetables
// @desc    Create new timetable
// @access  Private (Admin only)
router.post('/', [
  authMiddleware,
  roleAuth(['admin']),
  body('class').isMongoId(),
  body('academicYear').trim().isLength({ min: 1 }),
  body('term').isIn(['1st Term', '2nd Term', '3rd Term', 'Annual']),
  body('effectiveFrom').isISO8601()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { class: classId, academicYear, term, schedule, effectiveFrom, effectiveTo } = req.body;
    
    // Check if class exists
    const classExists = await Class.findById(classId);
    if (!classExists) {
      return res.status(404).json({ message: 'Class not found' });
    }
    
    // Check if timetable already exists for this class, year, and term
    const existingTimetable = await Timetable.findOne({
      class: classId,
      academicYear,
      term,
      isActive: true
    });
    
    if (existingTimetable) {
      return res.status(400).json({ message: 'Timetable already exists for this class and term' });
    }
    
    const timetable = new Timetable({
      class: classId,
      academicYear,
      term,
      schedule: schedule || {},
      effectiveFrom: new Date(effectiveFrom),
      effectiveTo: effectiveTo ? new Date(effectiveTo) : null,
      status: 'draft',
      createdBy: req.user.userId
    });
    
    await timetable.save();
    await timetable.populate('class', 'name grade section');
    
    res.status(201).json({
      message: 'Timetable created successfully',
      timetable
    });
    
  } catch (error) {
    console.error('Create timetable error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/timetables/:id
// @desc    Update timetable
// @access  Private (Admin only)
router.put('/:id', [
  authMiddleware,
  roleAuth(['admin'])
], async (req, res) => {
  try {
    const timetable = await Timetable.findById(req.params.id);
    
    if (!timetable) {
      return res.status(404).json({ message: 'Timetable not found' });
    }
    
    const updates = { ...req.body };
    updates.updatedBy = req.user.userId;
    
    // Add to change history
    timetable.changeHistory.push({
      changedBy: req.user.userId,
      changeType: 'updated',
      description: 'Timetable updated',
      changes: updates
    });
    
    Object.assign(timetable, updates);
    await timetable.save();
    
    await timetable.populate('class', 'name grade section');
    
    res.json({
      message: 'Timetable updated successfully',
      timetable
    });
    
  } catch (error) {
    console.error('Update timetable error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/timetables/:id/publish
// @desc    Publish timetable
// @access  Private (Admin only)
router.put('/:id/publish', [
  authMiddleware,
  roleAuth(['admin'])
], async (req, res) => {
  try {
    const timetable = await Timetable.findById(req.params.id);
    
    if (!timetable) {
      return res.status(404).json({ message: 'Timetable not found' });
    }
    
    timetable.status = 'published';
    timetable.updatedBy = req.user.userId;
    
    timetable.changeHistory.push({
      changedBy: req.user.userId,
      changeType: 'published',
      description: 'Timetable published'
    });
    
    await timetable.save();
    
    res.json({
      message: 'Timetable published successfully',
      timetable
    });
    
  } catch (error) {
    console.error('Publish timetable error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/timetables/:id/special-schedule
// @desc    Add special schedule for a specific date
// @access  Private (Admin only)
router.post('/:id/special-schedule', [
  authMiddleware,
  roleAuth(['admin']),
  body('date').isISO8601(),
  body('reason').trim().isLength({ min: 1 }),
  body('schedule').isArray()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const timetable = await Timetable.findById(req.params.id);
    
    if (!timetable) {
      return res.status(404).json({ message: 'Timetable not found' });
    }
    
    const { date, reason, schedule } = req.body;
    
    // Check if special schedule already exists for this date
    const existingSchedule = timetable.specialSchedules.find(
      special => special.date.toDateString() === new Date(date).toDateString()
    );
    
    if (existingSchedule) {
      return res.status(400).json({ message: 'Special schedule already exists for this date' });
    }
    
    timetable.specialSchedules.push({
      date: new Date(date),
      reason,
      schedule
    });
    
    timetable.updatedBy = req.user.userId;
    await timetable.save();
    
    res.json({
      message: 'Special schedule added successfully',
      timetable
    });
    
  } catch (error) {
    console.error('Add special schedule error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/timetables/:id/holiday
// @desc    Add holiday
// @access  Private (Admin only)
router.post('/:id/holiday', [
  authMiddleware,
  roleAuth(['admin']),
  body('date').isISO8601(),
  body('name').trim().isLength({ min: 1 }),
  body('type').isIn(['national', 'religious', 'school', 'emergency'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const timetable = await Timetable.findById(req.params.id);
    
    if (!timetable) {
      return res.status(404).json({ message: 'Timetable not found' });
    }
    
    const { date, name, type } = req.body;
    
    timetable.holidays.push({
      date: new Date(date),
      name,
      type
    });
    
    timetable.updatedBy = req.user.userId;
    await timetable.save();
    
    res.json({
      message: 'Holiday added successfully',
      timetable
    });
    
  } catch (error) {
    console.error('Add holiday error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
