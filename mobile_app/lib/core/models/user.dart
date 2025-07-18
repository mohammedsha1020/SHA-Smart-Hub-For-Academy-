class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phoneNumber;
  final String? profileImage;
  final bool isActive;
  final StudentInfo? studentInfo;
  final ParentInfo? parentInfo;
  final StaffInfo? staffInfo;
  final FinanceInfo? financeInfo;
  final NotificationSettings? notificationSettings;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phoneNumber,
    this.profileImage,
    required this.isActive,
    this.studentInfo,
    this.parentInfo,
    this.staffInfo,
    this.financeInfo,
    this.notificationSettings,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      isActive: json['isActive'] ?? true,
      studentInfo: json['studentInfo'] != null 
          ? StudentInfo.fromJson(json['studentInfo']) 
          : null,
      parentInfo: json['parentInfo'] != null 
          ? ParentInfo.fromJson(json['parentInfo']) 
          : null,
      staffInfo: json['staffInfo'] != null 
          ? StaffInfo.fromJson(json['staffInfo']) 
          : null,
      financeInfo: json['financeInfo'] != null 
          ? FinanceInfo.fromJson(json['financeInfo']) 
          : null,
      notificationSettings: json['notificationSettings'] != null 
          ? NotificationSettings.fromJson(json['notificationSettings']) 
          : null,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isActive': isActive,
      'studentInfo': studentInfo?.toJson(),
      'parentInfo': parentInfo?.toJson(),
      'staffInfo': staffInfo?.toJson(),
      'financeInfo': financeInfo?.toJson(),
      'notificationSettings': notificationSettings?.toJson(),
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StudentInfo {
  final String? studentId;
  final String? classId;
  final String? rollNumber;
  final DateTime? admissionDate;
  final String? parentId;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? medicalInfo;

  StudentInfo({
    this.studentId,
    this.classId,
    this.rollNumber,
    this.admissionDate,
    this.parentId,
    this.dateOfBirth,
    this.bloodGroup,
    this.medicalInfo,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentId: json['studentId'],
      classId: json['class'],
      rollNumber: json['rollNumber'],
      admissionDate: json['admissionDate'] != null 
          ? DateTime.parse(json['admissionDate']) 
          : null,
      parentId: json['parentId'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      bloodGroup: json['bloodGroup'],
      medicalInfo: json['medicalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'class': classId,
      'rollNumber': rollNumber,
      'admissionDate': admissionDate?.toIso8601String(),
      'parentId': parentId,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'medicalInfo': medicalInfo,
    };
  }
}

class ParentInfo {
  final List<String>? children;
  final String? occupation;
  final Address? address;

  ParentInfo({
    this.children,
    this.occupation,
    this.address,
  });

  factory ParentInfo.fromJson(Map<String, dynamic> json) {
    return ParentInfo(
      children: json['children']?.cast<String>(),
      occupation: json['occupation'],
      address: json['address'] != null 
          ? Address.fromJson(json['address']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'children': children,
      'occupation': occupation,
      'address': address?.toJson(),
    };
  }
}

class StaffInfo {
  final String? employeeId;
  final String? department;
  final String? position;
  final List<String>? classesAssigned;
  final List<String>? subjects;
  final DateTime? joiningDate;

  StaffInfo({
    this.employeeId,
    this.department,
    this.position,
    this.classesAssigned,
    this.subjects,
    this.joiningDate,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      employeeId: json['employeeId'],
      department: json['department'],
      position: json['position'],
      classesAssigned: json['classesAssigned']?.cast<String>(),
      subjects: json['subjects']?.cast<String>(),
      joiningDate: json['joiningDate'] != null 
          ? DateTime.parse(json['joiningDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'department': department,
      'position': position,
      'classesAssigned': classesAssigned,
      'subjects': subjects,
      'joiningDate': joiningDate?.toIso8601String(),
    };
  }
}

class FinanceInfo {
  final String? employeeId;
  final String? department;
  final List<String>? permissions;

  FinanceInfo({
    this.employeeId,
    this.department,
    this.permissions,
  });

  factory FinanceInfo.fromJson(Map<String, dynamic> json) {
    return FinanceInfo(
      employeeId: json['employeeId'],
      department: json['department'],
      permissions: json['permissions']?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'department': department,
      'permissions': permissions,
    };
  }
}

class NotificationSettings {
  final bool email;
  final bool sms;
  final bool push;

  NotificationSettings({
    required this.email,
    required this.sms,
    required this.push,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      email: json['email'] ?? true,
      sms: json['sms'] ?? true,
      push: json['push'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'sms': sms,
      'push': push,
    };
  }
}

class Address {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  Address({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }
}
