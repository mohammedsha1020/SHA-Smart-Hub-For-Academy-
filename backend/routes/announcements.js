const express = require('express');
const { body, validationResult } = require('express-validator');
const Announcement = require('../models/Announcement');
const User = require('../models/User');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/announcements
// @desc    Get announcements based on user role and access
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { status, type, page = 1, limit = 10 } = req.query;
    const user = await User.findById(req.user.userId).populate('parentInfo.children studentInfo.class staffInfo.classesAssigned');
    
    let query = { status: 'published', isActive: true };
    
    // Add filters
    if (type) query.type = type;
    
    // Get all announcements that might be visible to user
    let announcements = await Announcement.find(query)
      .populate('createdBy', 'firstName lastName role')
      .populate('targetAudience.classes', 'name grade section')
      .sort({ priority: -1, publishDate: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);
    
    // Filter announcements based on user access
    announcements = announcements.filter(announcement => 
      announcement.isVisibleToUser(user)
    );
    
    const total = announcements.length;
    
    res.json({
      announcements,
      pagination: {
        current: page,
        pages: Math.ceil(total / limit),
        total
      }
    });
    
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/announcements
// @desc    Create new announcement
// @access  Private (Admin, Staff only)
router.post('/', [
  authMiddleware,
  roleAuth(['admin', 'staff']),
  body('title').trim().isLength({ min: 1 }),
  body('content').trim().isLength({ min: 1 }),
  body('type').isIn(['general', 'urgent', 'academic', 'finance', 'event', 'holiday']),
  body('priority').isIn(['low', 'medium', 'high', 'urgent'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const {
      title,
      content,
      type,
      priority,
      targetAudience,
      attachments,
      publishDate,
      expiryDate,
      isScheduled
    } = req.body;
    
    const announcement = new Announcement({
      title,
      content,
      type,
      priority,
      targetAudience: targetAudience || { roles: ['staff', 'student', 'parent'] },
      attachments: attachments || [],
      publishDate: publishDate || new Date(),
      expiryDate,
      isScheduled: isScheduled || false,
      status: isScheduled ? 'draft' : 'published',
      createdBy: req.user.userId
    });
    
    await announcement.save();
    await announcement.populate('createdBy', 'firstName lastName role');
    
    res.status(201).json({
      message: 'Announcement created successfully',
      announcement
    });
    
  } catch (error) {
    console.error('Create announcement error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/announcements/:id
// @desc    Update announcement
// @access  Private (Admin, Creator only)
router.put('/:id', [
  authMiddleware,
  body('title').optional().trim().isLength({ min: 1 }),
  body('content').optional().trim().isLength({ min: 1 })
], async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    // Check if user can edit (admin or creator)
    if (req.user.role !== 'admin' && announcement.createdBy.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const updates = req.body;
    updates.updatedBy = req.user.userId;
    
    Object.assign(announcement, updates);
    await announcement.save();
    
    res.json({
      message: 'Announcement updated successfully',
      announcement
    });
    
  } catch (error) {
    console.error('Update announcement error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/announcements/:id/read
// @desc    Mark announcement as read
// @access  Private
router.post('/:id/read', authMiddleware, async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    // Check if already read
    const alreadyRead = announcement.readBy.find(
      read => read.user.toString() === req.user.userId
    );
    
    if (!alreadyRead) {
      announcement.readBy.push({
        user: req.user.userId,
        readAt: new Date()
      });
      announcement.viewCount += 1;
      await announcement.save();
    }
    
    res.json({ message: 'Announcement marked as read' });
    
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/announcements/:id
// @desc    Delete announcement
// @access  Private (Admin only)
router.delete('/:id', [
  authMiddleware,
  roleAuth(['admin'])
], async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    await announcement.deleteOne();
    
    res.json({ message: 'Announcement deleted successfully' });
    
  } catch (error) {
    console.error('Delete announcement error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
