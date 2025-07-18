const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Authentication middleware
const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const user = await User.findById(decoded.userId);
    if (!user || !user.isActive) {
      return res.status(401).json({ message: 'Invalid token or user deactivated.' });
    }

    req.user = {
      userId: user._id,
      role: user.role,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName
    };
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'Invalid token.' });
    } else if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired.' });
    }
    console.error('Auth middleware error:', error);
    res.status(500).json({ message: 'Server error.' });
  }
};

// Role-based authorization middleware
const roleAuth = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required.' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: 'Access denied. Insufficient permissions.',
        requiredRoles: allowedRoles,
        userRole: req.user.role
      });
    }

    next();
  };
};

// Middleware to check if user can access specific student data
const studentAccessAuth = async (req, res, next) => {
  try {
    const { studentId } = req.params;
    const { role, userId } = req.user;

    if (role === 'admin' || role === 'finance') {
      // Admins and finance users have access to all students
      return next();
    }

    if (role === 'student') {
      // Students can only access their own data
      if (studentId !== userId.toString()) {
        return res.status(403).json({ message: 'Access denied to other student data.' });
      }
      return next();
    }

    if (role === 'parent') {
      // Parents can only access their children's data
      const parent = await User.findById(userId);
      const childrenIds = parent.parentInfo.children.map(child => child.toString());
      
      if (!childrenIds.includes(studentId)) {
        return res.status(403).json({ message: 'Access denied to student data.' });
      }
      return next();
    }

    if (role === 'staff') {
      // Staff can only access students in their assigned classes
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const classIds = staff.staffInfo.classesAssigned.map(cls => cls._id.toString());
      
      const student = await User.findById(studentId);
      if (!student || !classIds.includes(student.studentInfo.class.toString())) {
        return res.status(403).json({ message: 'Access denied to student data.' });
      }
      return next();
    }

    res.status(403).json({ message: 'Access denied.' });

  } catch (error) {
    console.error('Student access auth error:', error);
    res.status(500).json({ message: 'Server error.' });
  }
};

module.exports = {
  authMiddleware,
  roleAuth,
  studentAccessAuth
};
