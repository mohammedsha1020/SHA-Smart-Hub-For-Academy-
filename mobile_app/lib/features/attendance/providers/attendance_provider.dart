import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/api_response.dart';

// Attendance data models
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final String status; // present, absent, late, excused
  final String? reason;
  final String? notes;
  final String markedBy;
  final DateTime markedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
    required this.markedBy,
    required this.markedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['_id'] ?? '',
      studentId: json['student']?['_id'] ?? json['studentId'] ?? '',
      studentName: json['student'] != null
          ? '${json['student']['firstName'] ?? ''} ${json['student']['lastName'] ?? ''}'.trim()
          : json['studentName'] ?? '',
      className: json['class']?['name'] ?? json['className'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
      reason: json['reason'],
      notes: json['notes'],
      markedBy: json['markedBy']?['firstName'] ?? json['markedBy'] ?? '',
      markedAt: DateTime.parse(json['markedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'date': date.toIso8601String(),
      'status': status,
      'reason': reason,
      'notes': notes,
      'markedBy': markedBy,
      'markedAt': markedAt.toIso8601String(),
    };
  }
}

class AttendanceStats {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendanceRate;
  final Map<String, int> classSummary;

  AttendanceStats({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendanceRate,
    required this.classSummary,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalStudents: json['totalStudents'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
      lateCount: json['lateCount'] ?? 0,
      excusedCount: json['excusedCount'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0).toDouble(),
      classSummary: Map<String, int>.from(json['classSummary'] ?? {}),
    );
  }
}

class StudentAttendanceSummary {
  final String studentId;
  final String studentName;
  final String className;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int excusedDays;
  final double attendancePercentage;
  final List<AttendanceRecord> recentRecords;

  StudentAttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.excusedDays,
    required this.attendancePercentage,
    required this.recentRecords,
  });

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummary(
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      className: json['className'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      excusedDays: json['excusedDays'] ?? 0,
      attendancePercentage: (json['attendancePercentage'] ?? 0).toDouble(),
      recentRecords: (json['recentRecords'] as List?)
          ?.map((r) => AttendanceRecord.fromJson(r))
          .toList() ?? [],
    );
  }
}

// Attendance state classes
class AttendanceState {
  final bool isLoading;
  final List<AttendanceRecord> records;
  final AttendanceStats? todayStats;
  final StudentAttendanceSummary? studentSummary;
  final String? error;
  final DateTime selectedDate;
  final String? selectedClass;
  final String? selectedStudent;

  AttendanceState({
    this.isLoading = false,
    this.records = const [],
    this.todayStats,
    this.studentSummary,
    this.error,
    DateTime? selectedDate,
    this.selectedClass,
    this.selectedStudent,
  }) : selectedDate = selectedDate ?? DateTime.now();

  AttendanceState copyWith({
    bool? isLoading,
    List<AttendanceRecord>? records,
    AttendanceStats? todayStats,
    StudentAttendanceSummary? studentSummary,
    String? error,
    DateTime? selectedDate,
    String? selectedClass,
    String? selectedStudent,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      todayStats: todayStats ?? this.todayStats,
      studentSummary: studentSummary ?? this.studentSummary,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedClass: selectedClass ?? this.selectedClass,
      selectedStudent: selectedStudent ?? this.selectedStudent,
    );
  }
}

// Attendance provider
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final ApiService _apiService;

  AttendanceNotifier(this._apiService) : super(AttendanceState());

  Future<void> loadTodayStats() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await _apiService.get('/attendance/stats/$dateStr');
      if (response.isSuccess && response.data != null) {
        final stats = AttendanceStats.fromJson(response.data!);
        state = state.copyWith(todayStats: stats);
      }
    } catch (e) {
      print('Failed to load today stats: $e');
    }
  }

  Future<void> loadAttendanceForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null, selectedDate: date);
    
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final queryParams = <String, String>{'date': dateStr};
      
      if (state.selectedClass != null) {
        queryParams['class'] = state.selectedClass!;
      }
      
      final response = await _apiService.get('/attendance', queryParams: queryParams);
      if (response.isSuccess && response.data != null) {
        final List<dynamic> recordsJson = response.data!['records'] ?? [];
        final records = recordsJson.map((r) => AttendanceRecord.fromJson(r)).toList();
        
        state = state.copyWith(
          isLoading: false,
          records: records,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load attendance',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendance: $e',
      );
    }
  }

  Future<void> loadStudentSummary(String studentId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.get('/attendance/student/$studentId/summary', queryParams: queryParams);
      if (response.isSuccess && response.data != null) {
        final summary = StudentAttendanceSummary.fromJson(response.data!);
        state = state.copyWith(studentSummary: summary);
      }
    } catch (e) {
      print('Failed to load student summary: $e');
    }
  }

  Future<bool> markAttendance(String studentId, String status, {String? reason, String? notes}) async {
    try {
      final response = await _apiService.post('/attendance/mark', data: {
        'student': studentId,
        'date': state.selectedDate.toIso8601String(),
        'status': status,
        'reason': reason,
        'notes': notes,
      });
      
      if (response.isSuccess) {
        // Reload attendance for current date
        await loadAttendanceForDate(state.selectedDate);
        await loadTodayStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to mark attendance');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark attendance: $e');
      return false;
    }
  }

  Future<bool> markBulkAttendance(List<Map<String, dynamic>> attendanceData) async {
    try {
      final response = await _apiService.post('/attendance/bulk-mark', data: {
        'attendanceData': attendanceData,
        'date': state.selectedDate.toIso8601String(),
      });
      
      if (response.isSuccess) {
        // Reload attendance for current date
        await loadAttendanceForDate(state.selectedDate);
        await loadTodayStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to mark bulk attendance');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark bulk attendance: $e');
      return false;
    }
  }

  Future<bool> updateAttendance(String recordId, String status, {String? reason, String? notes}) async {
    try {
      final response = await _apiService.put('/attendance/$recordId', data: {
        'status': status,
        'reason': reason,
        'notes': notes,
      });
      
      if (response.isSuccess) {
        // Update local state
        final updatedRecords = state.records.map((record) {
          if (record.id == recordId) {
            return AttendanceRecord.fromJson({
              ...record.toJson(),
              'status': status,
              'reason': reason,
              'notes': notes,
            });
          }
          return record;
        }).toList();
        
        state = state.copyWith(records: updatedRecords);
        await loadTodayStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to update attendance');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update attendance: $e');
      return false;
    }
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadAttendanceForDate(date);
  }

  void setSelectedClass(String? className) {
    state = state.copyWith(selectedClass: className);
    loadAttendanceForDate(state.selectedDate);
  }

  void setSelectedStudent(String? studentId) {
    state = state.copyWith(selectedStudent: studentId);
    if (studentId != null) {
      loadStudentSummary(studentId);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider instances
final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AttendanceNotifier(apiService);
});

// Computed providers
final todayAttendanceRateProvider = Provider<double>((ref) {
  final attendanceState = ref.watch(attendanceProvider);
  final stats = attendanceState.todayStats;
  if (stats == null || stats.totalStudents == 0) return 0.0;
  return stats.attendanceRate;
});

final absentStudentsTodayProvider = Provider<List<AttendanceRecord>>((ref) {
  final attendanceState = ref.watch(attendanceProvider);
  final today = DateTime.now();
  final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  return attendanceState.records
      .where((record) {
        final recordDateStr = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
        return recordDateStr == todayStr && record.status == 'absent';
      })
      .toList();
});

final attendanceByStatusProvider = Provider<Map<String, List<AttendanceRecord>>>((ref) {
  final attendanceState = ref.watch(attendanceProvider);
  final Map<String, List<AttendanceRecord>> byStatus = {
    'present': [],
    'absent': [],
    'late': [],
    'excused': [],
  };
  
  for (final record in attendanceState.records) {
    if (byStatus.containsKey(record.status)) {
      byStatus[record.status]!.add(record);
    }
  }
  
  return byStatus;
});
