import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/api_response.dart';

// Finance data models
class Fee {
  final String id;
  final String studentId;
  final String studentName;
  final String category;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final String status;
  final List<Payment> payments;
  final DateTime createdAt;

  Fee({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.category,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
    required this.payments,
    required this.createdAt,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['_id'] ?? '',
      studentId: json['student']?['_id'] ?? '',
      studentName: '${json['student']?['firstName'] ?? ''} ${json['student']?['lastName'] ?? ''}',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? 0).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      payments: (json['payments'] as List?)?.map((p) => Payment.fromJson(p)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Payment {
  final String id;
  final double amount;
  final String method;
  final String? reference;
  final DateTime date;

  Payment({
    required this.id,
    required this.amount,
    required this.method,
    this.reference,
    required this.date,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['method'] ?? '',
      reference: json['reference'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class FinancialSummary {
  final double totalFees;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final int activeStudents;
  final List<CategorySummary> categoryBreakdown;

  FinancialSummary({
    required this.totalFees,
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.activeStudents,
    required this.categoryBreakdown,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalFees: (json['totalFees'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      totalPending: (json['totalPending'] ?? 0).toDouble(),
      totalOverdue: (json['totalOverdue'] ?? 0).toDouble(),
      activeStudents: json['activeStudents'] ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List?)
          ?.map((c) => CategorySummary.fromJson(c))
          .toList() ?? [],
    );
  }
}

class CategorySummary {
  final String category;
  final double amount;
  final int count;

  CategorySummary({
    required this.category,
    required this.amount,
    required this.count,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

// Finance state classes
class FinanceState {
  final bool isLoading;
  final List<Fee> fees;
  final FinancialSummary? summary;
  final String? error;

  FinanceState({
    this.isLoading = false,
    this.fees = const [],
    this.summary,
    this.error,
  });

  FinanceState copyWith({
    bool? isLoading,
    List<Fee>? fees,
    FinancialSummary? summary,
    String? error,
  }) {
    return FinanceState(
      isLoading: isLoading ?? this.isLoading,
      fees: fees ?? this.fees,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

// Finance provider
class FinanceNotifier extends StateNotifier<FinanceState> {
  final ApiService _apiService;

  FinanceNotifier(this._apiService) : super(FinanceState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/finance/dashboard');
      if (response.isSuccess && response.data != null) {
        final summary = FinancialSummary.fromJson(response.data!);
        state = state.copyWith(
          isLoading: false,
          summary: summary,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load dashboard',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard: $e',
      );
    }
  }

  Future<void> loadFees({String? category, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      
      final response = await _apiService.get('/finance/fees', queryParams: queryParams);
      if (response.isSuccess && response.data != null) {
        final List<dynamic> feesJson = response.data!['fees'] ?? [];
        final fees = feesJson.map((f) => Fee.fromJson(f)).toList();
        
        state = state.copyWith(
          isLoading: false,
          fees: fees,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load fees',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load fees: $e',
      );
    }
  }

  Future<bool> addPayment(String feeId, double amount, String method) async {
    try {
      final response = await _apiService.post('/finance/fees/$feeId/payment', data: {
        'amount': amount,
        'method': method,
        'date': DateTime.now().toIso8601String(),
      });
      
      if (response.isSuccess) {
        // Reload fees to get updated data
        await loadFees();
        await loadDashboard();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to add payment');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add payment: $e');
      return false;
    }
  }

  Future<bool> createFee({
    required String studentId,
    required String category,
    required double amount,
    required DateTime dueDate,
    String? description,
  }) async {
    try {
      final response = await _apiService.post('/finance/fees', data: {
        'student': studentId,
        'category': category,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'description': description,
      });
      
      if (response.isSuccess) {
        // Reload fees to get updated data
        await loadFees();
        await loadDashboard();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to create fee');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create fee: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider instances
final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FinanceNotifier(apiService);
});

// Computed providers
final totalPendingFeesProvider = Provider<double>((ref) {
  final financeState = ref.watch(financeProvider);
  return financeState.fees
      .where((fee) => fee.status == 'pending' || fee.status == 'partial')
      .fold(0.0, (sum, fee) => sum + fee.remainingAmount);
});

final overdueFeesProvider = Provider<List<Fee>>((ref) {
  final financeState = ref.watch(financeProvider);
  final now = DateTime.now();
  return financeState.fees
      .where((fee) => fee.dueDate.isBefore(now) && fee.remainingAmount > 0)
      .toList();
});

final recentPaymentsProvider = Provider<List<Payment>>((ref) {
  final financeState = ref.watch(financeProvider);
  final allPayments = <Payment>[];
  
  for (final fee in financeState.fees) {
    allPayments.addAll(fee.payments);
  }
  
  allPayments.sort((a, b) => b.date.compareTo(a.date));
  return allPayments.take(10).toList();
});
