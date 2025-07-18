const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Class = require('../models/Class');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/users
// @desc    Get users based on role and permissions
// @access  Private
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { role, search, classId, limit = 50 } = req.query;
    const { role: userRole, userId } = req.user;
    
    let query = {};
    let allowedRoles = [];
    
    // Define what roles each user type can see
    if (userRole === 'admin') {
      allowedRoles = ['admin', 'finance', 'staff', 'parent', 'student'];
    } else if (userRole === 'finance') {
      allowedRoles = ['staff', 'parent', 'student'];
    } else if (userRole === 'staff') {
      allowedRoles = ['parent', 'student'];
    } else {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    // Filter by role if specified
    if (role && allowedRoles.includes(role)) {
      query.role = role;
    } else {
      query.role = { $in: allowedRoles };
    }
    
    // Add search functionality
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Filter by class if specified
    if (classId) {
      query['studentInfo.class'] = classId;
    }
    
    const users = await User.find(query)
      .populate('studentInfo.class', 'name grade section')
      .populate('staffInfo.classesAssigned', 'name grade section')
      .populate('parentInfo.children', 'firstName lastName studentInfo')
      .limit(parseInt(limit))
      .sort({ firstName: 1, lastName: 1 });
    
    res.json({ users });
    
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/users/:id
// @desc    Get user by ID
// @access  Private
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { role: userRole, userId } = req.user;
    
    // Check permissions
    if (userRole !== 'admin' && userRole !== 'finance' && id !== userId.toString()) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const user = await User.findById(id)
      .populate('studentInfo.class', 'name grade section')
      .populate('staffInfo.classesAssigned', 'name grade section')
      .populate('parentInfo.children', 'firstName lastName studentInfo');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ user });
    
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   PUT /api/users/:id
// @desc    Update user
// @access  Private
router.put('/:id', [
  authMiddleware,
  body('email').optional().isEmail().normalizeEmail(),
  body('firstName').optional().trim().isLength({ min: 1 }),
  body('lastName').optional().trim().isLength({ min: 1 }),
  body('phoneNumber').optional().trim().isLength({ min: 10 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { id } = req.params;
    const { role: userRole, userId } = req.user;
    
    // Check permissions - users can update their own profile, admins can update anyone
    if (userRole !== 'admin' && id !== userId.toString()) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Update allowed fields
    const allowedUpdates = ['firstName', 'lastName', 'phoneNumber', 'profileImage', 'notificationSettings'];
    const updates = {};
    
    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    });
    
    // Admins can update role-specific info
    if (userRole === 'admin') {
      if (req.body.staffInfo) updates.staffInfo = req.body.staffInfo;
      if (req.body.parentInfo) updates.parentInfo = req.body.parentInfo;
      if (req.body.studentInfo) updates.studentInfo = req.body.studentInfo;
      if (req.body.financeInfo) updates.financeInfo = req.body.financeInfo;
      if (req.body.isActive !== undefined) updates.isActive = req.body.isActive;
    }
    
    const updatedUser = await User.findByIdAndUpdate(
      id,
      { $set: updates },
      { new: true, runValidators: true }
    ).populate('studentInfo.class', 'name grade section')
     .populate('staffInfo.classesAssigned', 'name grade section')
     .populate('parentInfo.children', 'firstName lastName studentInfo');
    
    res.json({
      message: 'User updated successfully',
      user: updatedUser
    });
    
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   DELETE /api/users/:id
// @desc    Delete/Deactivate user
// @access  Private (Admin only)
router.delete('/:id', [
  authMiddleware,
  roleAuth(['admin'])
], async (req, res) => {
  try {
    const { id } = req.params;
    const { permanent } = req.query;
    
    if (permanent === 'true') {
      // Permanent deletion (use with caution)
      await User.findByIdAndDelete(id);
      res.json({ message: 'User permanently deleted' });
    } else {
      // Soft delete - just deactivate
      const user = await User.findByIdAndUpdate(
        id,
        { isActive: false },
        { new: true }
      );
      
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      
      res.json({ message: 'User deactivated successfully', user });
    }
    
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/users/students/by-class/:classId
// @desc    Get students in a specific class
// @access  Private
router.get('/students/by-class/:classId', authMiddleware, async (req, res) => {
  try {
    const { classId } = req.params;
    const { role: userRole, userId } = req.user;
    
    // Check if user has access to this class
    if (userRole === 'staff') {
      const staff = await User.findById(userId);
      const assignedClassIds = staff.staffInfo.classesAssigned.map(cls => cls.toString());
      
      if (!assignedClassIds.includes(classId)) {
        return res.status(403).json({ message: 'Access denied to this class' });
      }
    } else if (userRole !== 'admin' && userRole !== 'finance') {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const students = await User.find({
      role: 'student',
      'studentInfo.class': classId,
      isActive: true
    })
    .populate('studentInfo.class', 'name grade section')
    .populate('studentInfo.parentId', 'firstName lastName email phoneNumber')
    .sort({ 'studentInfo.rollNumber': 1 });
    
    res.json({ students });
    
  } catch (error) {
    console.error('Get students by class error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
