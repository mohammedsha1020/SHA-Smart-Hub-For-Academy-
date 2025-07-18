const mongoose = require('mongoose');

const timetableSchema = new mongoose.Schema({
  class: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Class',
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
  
  // Weekly schedule
  schedule: {
    monday: [{
      period: { type: Number, required: true },
      startTime: { type: String, required: true }, // "09:00"
      endTime: { type: String, required: true },   // "09:45"
      subject: { type: String, required: true },
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }],
    tuesday: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }],
    wednesday: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }],
    thursday: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }],
    friday: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }],
    saturday: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: {
        type: String,
        enum: ['regular', 'lab', 'library', 'sports', 'assembly', 'break', 'lunch'],
        default: 'regular'
      }
    }]
  },
  
  // Special schedules for events, exams, etc.
  specialSchedules: [{
    date: { type: Date, required: true },
    reason: { type: String, required: true }, // "Annual Sports Day", "Mid-term Exams"
    schedule: [{
      period: Number,
      startTime: String,
      endTime: String,
      subject: String,
      teacher: { 
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      room: String,
      type: String,
      description: String
    }]
  }],
  
  // Holidays and breaks
  holidays: [{
    date: { type: Date, required: true },
    name: { type: String, required: true },
    type: {
      type: String,
      enum: ['national', 'religious', 'school', 'emergency'],
      default: 'school'
    }
  }],
  
  // Status and metadata
  status: {
    type: String,
    enum: ['draft', 'published', 'archived'],
    default: 'draft'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  effectiveFrom: {
    type: Date,
    required: true
  },
  effectiveTo: Date,
  
  // Change history
  changeHistory: [{
    changedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    changeDate: {
      type: Date,
      default: Date.now
    },
    changeType: {
      type: String,
      enum: ['created', 'updated', 'published', 'archived']
    },
    description: String,
    changes: mongoose.Schema.Types.Mixed
  }],
  
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

// Indexes
timetableSchema.index({ class: 1, academicYear: 1, term: 1 });
timetableSchema.index({ status: 1, isActive: 1 });
timetableSchema.index({ effectiveFrom: 1, effectiveTo: 1 });

// Method to get schedule for a specific date
timetableSchema.methods.getScheduleForDate = function(date) {
  const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'lowercase' });
  
  // Check for special schedules first
  const specialSchedule = this.specialSchedules.find(special => 
    special.date.toDateString() === date.toDateString()
  );
  
  if (specialSchedule) {
    return {
      type: 'special',
      reason: specialSchedule.reason,
      schedule: specialSchedule.schedule
    };
  }
  
  // Check for holidays
  const holiday = this.holidays.find(holiday => 
    holiday.date.toDateString() === date.toDateString()
  );
  
  if (holiday) {
    return {
      type: 'holiday',
      name: holiday.name,
      holidayType: holiday.type,
      schedule: []
    };
  }
  
  // Return regular schedule
  return {
    type: 'regular',
    schedule: this.schedule[dayOfWeek] || []
  };
};

// Method to get teacher's schedule
timetableSchema.statics.getTeacherSchedule = async function(teacherId, date) {
  const dayOfWeek = date.toLocaleDateString('en-US', { weekday: 'lowercase' });
  
  const timetables = await this.find({
    status: 'published',
    isActive: true,
    effectiveFrom: { $lte: date },
    $or: [
      { effectiveTo: { $exists: false } },
      { effectiveTo: { $gte: date } }
    ]
  }).populate('class', 'name grade section');
  
  const teacherSchedule = [];
  
  timetables.forEach(timetable => {
    const daySchedule = timetable.schedule[dayOfWeek] || [];
    
    daySchedule.forEach(period => {
      if (period.teacher && period.teacher.toString() === teacherId.toString()) {
        teacherSchedule.push({
          class: timetable.class,
          period: period.period,
          startTime: period.startTime,
          endTime: period.endTime,
          subject: period.subject,
          room: period.room,
          type: period.type
        });
      }
    });
  });
  
  return teacherSchedule.sort((a, b) => a.period - b.period);
};

module.exports = mongoose.model('Timetable', timetableSchema);
