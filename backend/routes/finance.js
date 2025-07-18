const express = require('express');
const { body, validationResult } = require('express-validator');
const Fee = require('../models/Fee');
const User = require('../models/User');
const { authMiddleware, roleAuth } = require('../middleware/auth');
const router = express.Router();

// @route   GET /api/finance/fees
// @desc    Get fees based on user role
// @access  Private
router.get('/fees', authMiddleware, async (req, res) => {
  try {
    const { role, userId } = req.user;
    const { status, academicYear, term, studentId } = req.query;
    
    let query = {};
    
    // Build query based on user role
    if (role === 'parent') {
      // Parents can only see their children's fees
      const parent = await User.findById(userId).populate('parentInfo.children');
      const childrenIds = parent.parentInfo.children.map(child => child._id);
      query.student = { $in: childrenIds };
    } else if (role === 'student') {
      // Students can only see their own fees
      query.student = userId;
    } else if (role === 'staff') {
      // Staff can see fees for students in their assigned classes
      const staff = await User.findById(userId).populate('staffInfo.classesAssigned');
      const classIds = staff.staffInfo.classesAssigned.map(cls => cls._id);
      
      // Get all students in these classes
      const students = await User.find({
        'studentInfo.class': { $in: classIds },
        role: 'student'
      });
      const studentIds = students.map(student => student._id);
      query.student = { $in: studentIds };
      
      // If specific student requested, check if staff has access
      if (studentId) {
        if (studentIds.includes(studentId)) {
          query.student = studentId;
        } else {
          return res.status(403).json({ message: 'Access denied to this student\'s data' });
        }
      }
    } else if (role === 'finance' || role === 'admin') {
      // Finance users and admins can see all fees
      if (studentId) {
        query.student = studentId;
      }
    }
    
    // Add optional filters
    if (status) query.overallStatus = status;
    if (academicYear) query.academicYear = academicYear;
    if (term) query.term = term;
    
    const fees = await Fee.find(query)
      .populate('student', 'firstName lastName studentInfo')
      .populate('paymentHistory.receivedBy', 'firstName lastName')
      .sort({ createdAt: -1 });
    
    res.json({ fees });
    
  } catch (error) {
    console.error('Get fees error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/finance/fees
// @desc    Create new fee record
// @access  Private (Finance, Admin only)
router.post('/fees', [
  authMiddleware,
  roleAuth(['finance', 'admin']),
  body('student').isMongoId(),
  body('academicYear').trim().isLength({ min: 1 }),
  body('term').isIn(['1st Term', '2nd Term', '3rd Term', 'Annual']),
  body('feeCategories').isArray({ min: 1 }),
  body('totalAmount').isNumeric({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { student, academicYear, term, feeCategories, totalAmount, notes } = req.body;
    
    // Check if student exists
    const studentUser = await User.findById(student);
    if (!studentUser || studentUser.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    // Check if fee record already exists for this student, year, and term
    const existingFee = await Fee.findOne({ student, academicYear, term });
    if (existingFee) {
      return res.status(400).json({ message: 'Fee record already exists for this term' });
    }
    
    // Create new fee record
    const fee = new Fee({
      student,
      academicYear,
      term,
      feeCategories,
      totalAmount,
      notes,
      createdBy: req.user.userId
    });
    
    await fee.save();
    await fee.populate('student', 'firstName lastName studentInfo');
    
    res.status(201).json({
      message: 'Fee record created successfully',
      fee
    });
    
  } catch (error) {
    console.error('Create fee error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   POST /api/finance/fees/:feeId/payment
// @desc    Add payment to fee record
// @access  Private (Finance, Admin only)
router.post('/fees/:feeId/payment', [
  authMiddleware,
  roleAuth(['finance', 'admin']),
  body('amount').isNumeric({ min: 0.01 }),
  body('paymentMethod').isIn(['cash', 'card', 'bank_transfer', 'online', 'cheque']),
  body('category').trim().isLength({ min: 1 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { feeId } = req.params;
    const { amount, paymentMethod, category, transactionId, receiptNumber, notes } = req.body;
    
    const fee = await Fee.findById(feeId);
    if (!fee) {
      return res.status(404).json({ message: 'Fee record not found' });
    }
    
    // Check if the category exists in fee structure
    const feeCategory = fee.feeCategories.find(cat => cat.category === category);
    if (!feeCategory) {
      return res.status(400).json({ message: 'Invalid fee category' });
    }
    
    // Check if payment amount doesn't exceed remaining amount for this category
    if (amount > feeCategory.remainingAmount) {
      return res.status(400).json({ 
        message: `Payment amount exceeds remaining amount for ${category}` 
      });
    }
    
    // Add payment to history
    const payment = {
      transactionId: transactionId || `TXN${Date.now()}`,
      amount,
      paymentMethod,
      category,
      receivedBy: req.user.userId,
      receiptNumber: receiptNumber || `REC${Date.now()}`,
      notes,
      status: 'completed'
    };
    
    fee.paymentHistory.push(payment);
    fee.updatedBy = req.user.userId;
    
    await fee.save();
    await fee.populate('student', 'firstName lastName studentInfo');
    await fee.populate('paymentHistory.receivedBy', 'firstName lastName');
    
    res.json({
      message: 'Payment added successfully',
      fee,
      payment: fee.paymentHistory[fee.paymentHistory.length - 1]
    });
    
  } catch (error) {
    console.error('Add payment error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/finance/dashboard
// @desc    Get finance dashboard data
// @access  Private (Finance, Admin only)
router.get('/dashboard', [
  authMiddleware,
  roleAuth(['finance', 'admin'])
], async (req, res) => {
  try {
    const { academicYear } = req.query;
    const currentYear = academicYear || new Date().getFullYear().toString();
    
    // Get overall statistics
    const totalFees = await Fee.aggregate([
      { $match: { academicYear: currentYear } },
      {
        $group: {
          _id: null,
          totalAmount: { $sum: '$totalAmount' },
          totalPaid: { $sum: '$totalPaid' },
          totalPending: { $sum: '$totalPending' },
          count: { $sum: 1 }
        }
      }
    ]);
    
    // Get status-wise breakdown
    const statusBreakdown = await Fee.aggregate([
      { $match: { academicYear: currentYear } },
      {
        $group: {
          _id: '$overallStatus',
          count: { $sum: 1 },
          amount: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    // Get overdue fees
    const overdueFees = await Fee.find({
      academicYear: currentYear,
      overallStatus: 'overdue'
    })
    .populate('student', 'firstName lastName studentInfo')
    .limit(10);
    
    // Get recent payments
    const recentPayments = await Fee.aggregate([
      { $match: { academicYear: currentYear } },
      { $unwind: '$paymentHistory' },
      { $sort: { 'paymentHistory.paymentDate': -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: 'users',
          localField: 'student',
          foreignField: '_id',
          as: 'studentInfo'
        }
      }
    ]);
    
    res.json({
      overview: totalFees[0] || { totalAmount: 0, totalPaid: 0, totalPending: 0, count: 0 },
      statusBreakdown,
      overdueFees,
      recentPayments,
      academicYear: currentYear
    });
    
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @route   GET /api/finance/reports
// @desc    Generate finance reports
// @access  Private (Finance, Admin only)
router.get('/reports', [
  authMiddleware,
  roleAuth(['finance', 'admin'])
], async (req, res) => {
  try {
    const { type, academicYear, startDate, endDate, classId } = req.query;
    const currentYear = academicYear || new Date().getFullYear().toString();
    
    let matchQuery = { academicYear: currentYear };
    
    // Add date filter if provided
    if (startDate && endDate) {
      matchQuery.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }
    
    // Add class filter if provided
    if (classId) {
      const studentsInClass = await User.find({
        'studentInfo.class': classId,
        role: 'student'
      }).select('_id');
      const studentIds = studentsInClass.map(s => s._id);
      matchQuery.student = { $in: studentIds };
    }
    
    let reportData = {};
    
    switch (type) {
      case 'collection':
        reportData = await Fee.aggregate([
          { $match: matchQuery },
          { $unwind: '$paymentHistory' },
          {
            $group: {
              _id: {
                month: { $month: '$paymentHistory.paymentDate' },
                year: { $year: '$paymentHistory.paymentDate' }
              },
              totalCollected: { $sum: '$paymentHistory.amount' },
              paymentCount: { $sum: 1 }
            }
          },
          { $sort: { '_id.year': 1, '_id.month': 1 } }
        ]);
        break;
        
      case 'outstanding':
        reportData = await Fee.aggregate([
          { $match: { ...matchQuery, overallStatus: { $in: ['pending', 'overdue', 'partial'] } } },
          {
            $lookup: {
              from: 'users',
              localField: 'student',
              foreignField: '_id',
              as: 'studentInfo'
            }
          },
          {
            $project: {
              student: { $arrayElemAt: ['$studentInfo', 0] },
              totalAmount: 1,
              totalPaid: 1,
              totalPending: 1,
              overallStatus: 1,
              term: 1
            }
          }
        ]);
        break;
        
      case 'category':
        reportData = await Fee.aggregate([
          { $match: matchQuery },
          { $unwind: '$feeCategories' },
          {
            $group: {
              _id: '$feeCategories.category',
              totalAmount: { $sum: '$feeCategories.amount' },
              totalPaid: { $sum: '$feeCategories.paidAmount' },
              count: { $sum: 1 }
            }
          }
        ]);
        break;
        
      default:
        return res.status(400).json({ message: 'Invalid report type' });
    }
    
    res.json({
      reportType: type,
      data: reportData,
      generatedAt: new Date(),
      filters: { academicYear: currentYear, startDate, endDate, classId }
    });
    
  } catch (error) {
    console.error('Reports error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
