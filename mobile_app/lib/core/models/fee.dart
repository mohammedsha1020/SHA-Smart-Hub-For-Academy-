class Fee {
  final String id;
  final String student;
  final String academicYear;
  final String term;
  final List<FeeCategory> feeCategories;
  final double totalAmount;
  final double totalPaid;
  final double totalPending;
  final String overallStatus;
  final List<PaymentHistory> paymentHistory;
  final LateFee? lateFee;
  final Discount? discount;
  final String? notes;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Fee({
    required this.id,
    required this.student,
    required this.academicYear,
    required this.term,
    required this.feeCategories,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalPending,
    required this.overallStatus,
    required this.paymentHistory,
    this.lateFee,
    this.discount,
    this.notes,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['_id'],
      student: json['student'],
      academicYear: json['academicYear'],
      term: json['term'],
      feeCategories: (json['feeCategories'] as List)
          .map((e) => FeeCategory.fromJson(e))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      totalPaid: json['totalPaid'].toDouble(),
      totalPending: json['totalPending'].toDouble(),
      overallStatus: json['overallStatus'],
      paymentHistory: (json['paymentHistory'] as List)
          .map((e) => PaymentHistory.fromJson(e))
          .toList(),
      lateFee: json['lateFee'] != null ? LateFee.fromJson(json['lateFee']) : null,
      discount: json['discount'] != null ? Discount.fromJson(json['discount']) : null,
      notes: json['notes'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'student': student,
      'academicYear': academicYear,
      'term': term,
      'feeCategories': feeCategories.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'overallStatus': overallStatus,
      'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
      'lateFee': lateFee?.toJson(),
      'discount': discount?.toJson(),
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FeeCategory {
  final String category;
  final String? description;
  final double amount;
  final DateTime dueDate;
  final String status;
  final double paidAmount;
  final double remainingAmount;

  FeeCategory({
    required this.category,
    this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.paidAmount,
    required this.remainingAmount,
  });

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      category: json['category'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      status: json['status'],
      paidAmount: json['paidAmount'].toDouble(),
      remainingAmount: json['remainingAmount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
    };
  }
}

class PaymentHistory {
  final String? transactionId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? receivedBy;
  final String? category;
  final String? receiptNumber;
  final String? notes;
  final String status;

  PaymentHistory({
    this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.receivedBy,
    this.category,
    this.receiptNumber,
    this.notes,
    required this.status,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      transactionId: json['transactionId'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      paymentDate: DateTime.parse(json['paymentDate']),
      receivedBy: json['receivedBy'],
      category: json['category'],
      receiptNumber: json['receiptNumber'],
      notes: json['notes'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'receivedBy': receivedBy,
      'category': category,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'status': status,
    };
  }
}

class LateFee {
  final bool applicable;
  final double amount;
  final DateTime? appliedDate;

  LateFee({
    required this.applicable,
    required this.amount,
    this.appliedDate,
  });

  factory LateFee.fromJson(Map<String, dynamic> json) {
    return LateFee(
      applicable: json['applicable'],
      amount: json['amount'].toDouble(),
      appliedDate: json['appliedDate'] != null 
          ? DateTime.parse(json['appliedDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicable': applicable,
      'amount': amount,
      'appliedDate': appliedDate?.toIso8601String(),
    };
  }
}

class Discount {
  final String type;
  final double value;
  final String? reason;
  final String? appliedBy;
  final DateTime? appliedDate;

  Discount({
    required this.type,
    required this.value,
    this.reason,
    this.appliedBy,
    this.appliedDate,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      type: json['type'],
      value: json['value'].toDouble(),
      reason: json['reason'],
      appliedBy: json['appliedBy'],
      appliedDate: json['appliedDate'] != null 
          ? DateTime.parse(json['appliedDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'reason': reason,
      'appliedBy': appliedBy,
      'appliedDate': appliedDate?.toIso8601String(),
    };
  }
}
