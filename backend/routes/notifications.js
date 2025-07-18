const express = require('express');
const { body, validationResult } = require('express-validator');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/notifications
// @desc    Get user's notifications
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { status, type, page = 1, limit = 20 } = req.query;
    
    let query = { recipient: req.user.userId };
    
    if (status) query.status = status;
    if (type) query.type = type;
    
    const notifications = await Notification.find(query)
      .populate('createdBy', 'firstName lastName role')
      .sort({ priority: -1, createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({
      recipient: req.user.userId,
      status: 'unread'
    });
    
    res.json({
      notifications,
      unreadCount,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / limit),
        total
      }
    });
    
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/notifications
// @desc    Create notification (Admin/System only)
// @access  Private (Admin only)
router.post('/', [
  authMiddleware,
  roleAuth(['admin']),
  body('recipient').isMongoId(),
  body('title').trim().isLength({ min: 1 }),
  body('message').trim().isLength({ min: 1 }),
  body('type').isIn([
    'fee_reminder', 'fee_overdue', 'payment_confirmation',
    'announcement', 'attendance', 'grade_update', 'timetable_change',
    'event_reminder', 'general'
  ])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const notification = new Notification({
      ...req.body,
      createdBy: req.user.userId
    });
    
    await notification.save();
    await notification.populate('recipient', 'firstName lastName');
    
    res.status(201).json({
      message: 'Notification created successfully',
      notification
    });
    
  } catch (error) {
    console.error('Create notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/notifications/:id/read
// @desc    Mark notification as read
// @access  Private
router.put('/:id/read', authMiddleware, async (req, res) => {
  try {
    const notification = await Notification.findOne({
      _id: req.params.id,
      recipient: req.user.userId
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    if (notification.status !== 'read') {
      await notification.markAsRead();
    }
    
    res.json({ message: 'Notification marked as read', notification });
    
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/notifications/:id/archive
// @desc    Archive notification
// @access  Private
router.put('/:id/archive', authMiddleware, async (req, res) => {
  try {
    const notification = await Notification.findOne({
      _id: req.params.id,
      recipient: req.user.userId
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    await notification.archive();
    
    res.json({ message: 'Notification archived', notification });
    
  } catch (error) {
    console.error('Archive notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/notifications/mark-all-read
// @desc    Mark all notifications as read
// @access  Private
router.put('/mark-all-read', authMiddleware, async (req, res) => {
  try {
    await Notification.updateMany(
      { recipient: req.user.userId, status: 'unread' },
      { status: 'read', readAt: new Date() }
    );
    
    res.json({ message: 'All notifications marked as read' });
    
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/notifications/:id
// @desc    Delete notification
// @access  Private
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const notification = await Notification.findOneAndDelete({
      _id: req.params.id,
      recipient: req.user.userId
    });
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    res.json({ message: 'Notification deleted successfully' });
    
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/notifications/bulk
// @desc    Send bulk notifications
// @access  Private (Admin only)
router.post('/bulk', [
  authMiddleware,
  roleAuth(['admin']),
  body('recipients').isArray({ min: 1 }),
  body('title').trim().isLength({ min: 1 }),
  body('message').trim().isLength({ min: 1 }),
  body('type').isIn([
    'fee_reminder', 'fee_overdue', 'payment_confirmation',
    'announcement', 'attendance', 'grade_update', 'timetable_change',
    'event_reminder', 'general'
  ])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { recipients, title, message, type, priority = 'medium' } = req.body;
    
    const notifications = recipients.map(recipientId => ({
      recipient: recipientId,
      title,
      message,
      type,
      priority,
      createdBy: req.user.userId
    }));
    
    const createdNotifications = await Notification.insertMany(notifications);
    
    res.status(201).json({
      message: `${createdNotifications.length} notifications sent successfully`,
      count: createdNotifications.length
    });
    
  } catch (error) {
    console.error('Bulk notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
