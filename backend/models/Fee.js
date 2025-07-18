const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  student: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  academicYear: {
    type: String,
    required: true
  },
  term: {
    type: String,
    enum: ['1st Term', '2nd Term', '3rd Term', 'Annual'],
    required: true
  },
  
  // Fee breakdown
  feeCategories: [{
    category: {
      type: String,
      required: true,
      enum: ['tuition', 'library', 'laboratory', 'sports', 'transport', 'lunch', 'examination', 'development', 'other']
    },
    description: String,
    amount: {
      type: Number,
      required: true,
      min: 0
    },
    dueDate: {
      type: Date,
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'overdue', 'partial'],
      default: 'pending'
    },
    paidAmount: {
      type: Number,
      default: 0,
      min: 0
    },
    remainingAmount: {
      type: Number,
      default: function() { return this.amount; }
    }
  }],
  
  // Total calculations
  totalAmount: {
    type: Number,
    required: true,
    min: 0
  },
  totalPaid: {
    type: Number,
    default: 0,
    min: 0
  },
  totalPending: {
    type: Number,
    default: function() { return this.totalAmount; }
  },
  
  // Overall status
  overallStatus: {
    type: String,
    enum: ['pending', 'paid', 'overdue', 'partial'],
    default: 'pending'
  },
  
  // Payment history
  paymentHistory: [{
    transactionId: String,
    amount: {
      type: Number,
      required: true,
      min: 0
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'card', 'bank_transfer', 'online', 'cheque'],
      required: true
    },
    paymentDate: {
      type: Date,
      default: Date.now
    },
    receivedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    category: String, // which fee category this payment is for
    receiptNumber: String,
    notes: String,
    status: {
      type: String,
      enum: ['completed', 'pending', 'failed', 'refunded'],
      default: 'completed'
    }
  }],
  
  // Late fee information
  lateFee: {
    applicable: { type: Boolean, default: false },
    amount: { type: Number, default: 0 },
    appliedDate: Date
  },
  
  // Discount information
  discount: {
    type: { type: String, enum: ['percentage', 'fixed'] },
    value: { type: Number, default: 0 },
    reason: String,
    appliedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    appliedDate: Date
  },
  
  // Notifications sent
  notifications: [{
    type: {
      type: String,
      enum: ['reminder', 'overdue', 'payment_confirmation', 'late_fee']
    },
    sentDate: { type: Date, default: Date.now },
    method: [{ type: String, enum: ['email', 'sms', 'push'] }],
    message: String
  }],
  
  // Comments and notes
  notes: String,
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Calculate totals before saving
feeSchema.pre('save', function(next) {
  this.totalPaid = this.paymentHistory.reduce((sum, payment) => {
    return payment.status === 'completed' ? sum + payment.amount : sum;
  }, 0);
  
  this.totalPending = this.totalAmount - this.totalPaid;
  
  // Update overall status
  if (this.totalPending <= 0) {
    this.overallStatus = 'paid';
  } else if (this.totalPaid > 0) {
    this.overallStatus = 'partial';
  } else {
    // Check if any fee is overdue
    const now = new Date();
    const hasOverdue = this.feeCategories.some(fee => 
      fee.dueDate < now && fee.status !== 'paid'
    );
    this.overallStatus = hasOverdue ? 'overdue' : 'pending';
  }
  
  // Update individual fee categories
  this.feeCategories.forEach(feeCategory => {
    const categoryPayments = this.paymentHistory.filter(payment => 
      payment.category === feeCategory.category && payment.status === 'completed'
    );
    
    feeCategory.paidAmount = categoryPayments.reduce((sum, payment) => sum + payment.amount, 0);
    feeCategory.remainingAmount = feeCategory.amount - feeCategory.paidAmount;
    
    if (feeCategory.remainingAmount <= 0) {
      feeCategory.status = 'paid';
    } else if (feeCategory.paidAmount > 0) {
      feeCategory.status = 'partial';
    } else {
      const now = new Date();
      feeCategory.status = feeCategory.dueDate < now ? 'overdue' : 'pending';
    }
  });
  
  next();
});

// Index for better query performance
feeSchema.index({ student: 1, academicYear: 1, term: 1 });
feeSchema.index({ overallStatus: 1 });
feeSchema.index({ 'feeCategories.dueDate': 1 });

module.exports = mongoose.model('Fee', feeSchema);
