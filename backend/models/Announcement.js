const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  content: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['general', 'urgent', 'academic', 'finance', 'event', 'holiday'],
    default: 'general'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  
  // Target audience
  targetAudience: {
    roles: [{
      type: String,
      enum: ['admin', 'finance', 'staff', 'parent', 'student']
    }],
    classes: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class'
    }],
    specificUsers: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }]
  },
  
  // Media attachments
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileType: String,
    fileSize: Number
  }],
  
  // Scheduling
  publishDate: {
    type: Date,
    default: Date.now
  },
  expiryDate: Date,
  isScheduled: {
    type: Boolean,
    default: false
  },
  
  // Status
  status: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'draft'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Analytics
  viewCount: {
    type: Number,
    default: 0
  },
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Creator info
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

// Indexes for better performance
announcementSchema.index({ status: 1, publishDate: -1 });
announcementSchema.index({ type: 1 });
announcementSchema.index({ 'targetAudience.roles': 1 });
announcementSchema.index({ 'targetAudience.classes': 1 });
announcementSchema.index({ expiryDate: 1 });

// Method to check if announcement is visible to a user
announcementSchema.methods.isVisibleToUser = function(user) {
  const now = new Date();
  
  // Check if announcement is active and not expired
  if (!this.isActive || this.status !== 'published') return false;
  if (this.publishDate > now) return false;
  if (this.expiryDate && this.expiryDate < now) return false;
  
  // Check target audience
  const { targetAudience } = this;
  
  // If specific users are targeted
  if (targetAudience.specificUsers && targetAudience.specificUsers.length > 0) {
    return targetAudience.specificUsers.includes(user._id);
  }
  
  // If roles are targeted
  if (targetAudience.roles && targetAudience.roles.length > 0) {
    if (!targetAudience.roles.includes(user.role)) return false;
  }
  
  // If classes are targeted (for students and their parents)
  if (targetAudience.classes && targetAudience.classes.length > 0) {
    if (user.role === 'student') {
      return targetAudience.classes.includes(user.studentInfo.class);
    } else if (user.role === 'parent') {
      // Check if any of parent's children are in target classes
      return user.parentInfo.children.some(child => 
        targetAudience.classes.includes(child.studentInfo?.class)
      );
    } else if (user.role === 'staff') {
      // Check if staff teaches any of the target classes
      return user.staffInfo.classesAssigned.some(cls => 
        targetAudience.classes.includes(cls)
      );
    }
  }
  
  return true;
};

module.exports = mongoose.model('Announcement', announcementSchema);
