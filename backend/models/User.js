const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  firstName: {
    type: String,
    required: true
  },
  lastName: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['admin', 'finance', 'staff', 'parent', 'student'],
    required: true
  },
  phoneNumber: {
    type: String,
    required: true
  },
  profileImage: {
    type: String,
    default: ''
  },
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Role-specific fields
  staffInfo: {
    employeeId: String,
    department: String,
    position: String,
    classesAssigned: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Class' }],
    subjects: [String],
    joiningDate: Date
  },
  
  parentInfo: {
    children: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
    occupation: String,
    address: {
      street: String,
      city: String,
      state: String,
      zipCode: String,
      country: String
    }
  },
  
  studentInfo: {
    studentId: String,
    class: { type: mongoose.Schema.Types.ObjectId, ref: 'Class' },
    rollNumber: String,
    admissionDate: Date,
    parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    dateOfBirth: Date,
    bloodGroup: String,
    medicalInfo: String
  },
  
  financeInfo: {
    employeeId: String,
    department: String,
    permissions: [String] // specific finance permissions
  },
  
  // Notification preferences
  notificationSettings: {
    email: { type: Boolean, default: true },
    sms: { type: Boolean, default: true },
    push: { type: Boolean, default: true }
  },
  
  // Device tokens for push notifications
  deviceTokens: [String],
  
  lastLogin: Date,
  passwordResetToken: String,
  passwordResetExpires: Date
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove sensitive data when converting to JSON
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  delete user.passwordResetToken;
  delete user.passwordResetExpires;
  return user;
};

module.exports = mongoose.model('User', userSchema);
