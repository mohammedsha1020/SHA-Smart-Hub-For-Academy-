const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  recipient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: [
      'fee_reminder',
      'fee_overdue', 
      'payment_confirmation',
      'announcement',
      'attendance',
      'grade_update',
      'timetable_change',
      'event_reminder',
      'general'
    ],
    required: true
  },
  
  // Status
  status: {
    type: String,
    enum: ['unread', 'read', 'archived'],
    default: 'unread'
  },
  
  // Priority
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  
  // Delivery channels
  channels: {
    push: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      delivered: { type: Boolean, default: false },
      deliveredAt: Date
    },
    email: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      delivered: { type: Boolean, default: false },
      deliveredAt: Date
    },
    sms: {
      sent: { type: Boolean, default: false },
      sentAt: Date,
      delivered: { type: Boolean, default: false },
      deliveredAt: Date
    }
  },
  
  // Related data
  relatedData: {
    modelType: String, // 'Fee', 'Announcement', 'Attendance', etc.
    modelId: mongoose.Schema.Types.ObjectId,
    metadata: mongoose.Schema.Types.Mixed
  },
  
  // Actions
  actionRequired: {
    type: Boolean,
    default: false
  },
  actionUrl: String,
  actionText: String,
  
  // Timing
  scheduledFor: Date,
  readAt: Date,
  archivedAt: Date,
  
  // Creator
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }
}, {
  timestamps: true
});

// Indexes
notificationSchema.index({ recipient: 1, status: 1, createdAt: -1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ scheduledFor: 1 });
notificationSchema.index({ priority: 1 });

// Method to mark as read
notificationSchema.methods.markAsRead = function() {
  this.status = 'read';
  this.readAt = new Date();
  return this.save();
};

// Method to archive
notificationSchema.methods.archive = function() {
  this.status = 'archived';
  this.archivedAt = new Date();
  return this.save();
};

// Static method to create fee reminder notification
notificationSchema.statics.createFeeReminder = function(recipientId, feeData, daysUntilDue) {
  const urgency = daysUntilDue <= 1 ? 'urgent' : daysUntilDue <= 3 ? 'high' : 'medium';
  const message = daysUntilDue <= 0 
    ? `Fee payment of ₹${feeData.amount} is overdue. Please pay immediately.`
    : `Fee payment of ₹${feeData.amount} is due in ${daysUntilDue} day(s).`;
  
  return this.create({
    recipient: recipientId,
    title: daysUntilDue <= 0 ? 'Overdue Fee Payment' : 'Fee Payment Reminder',
    message,
    type: daysUntilDue <= 0 ? 'fee_overdue' : 'fee_reminder',
    priority: urgency,
    relatedData: {
      modelType: 'Fee',
      modelId: feeData._id,
      metadata: feeData
    },
    actionRequired: true,
    actionText: 'Pay Now',
    actionUrl: `/fees/${feeData._id}/pay`
  });
};

// Static method to create payment confirmation
notificationSchema.statics.createPaymentConfirmation = function(recipientId, paymentData) {
  return this.create({
    recipient: recipientId,
    title: 'Payment Confirmation',
    message: `Your payment of ₹${paymentData.amount} has been successfully processed. Receipt: ${paymentData.receiptNumber}`,
    type: 'payment_confirmation',
    priority: 'medium',
    relatedData: {
      modelType: 'Payment',
      modelId: paymentData._id,
      metadata: paymentData
    }
  });
};

module.exports = mongoose.model('Notification', notificationSchema);
