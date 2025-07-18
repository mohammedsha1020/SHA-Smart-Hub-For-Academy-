import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/api_response.dart';

// Student data models
class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String studentId;
  final String className;
  final String? parentId;
  final String? parentName;
  final String? parentPhone;
  final String status;
  final DateTime enrollmentDate;
  final Map<String, dynamic>? additionalInfo;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.studentId,
    required this.className,
    this.parentId,
    this.parentName,
    this.parentPhone,
    required this.status,
    required this.enrollmentDate,
    this.additionalInfo,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      studentId: json['studentId'] ?? '',
      className: json['class']?['name'] ?? json['className'] ?? '',
      parentId: json['parent']?['_id'],
      parentName: json['parent'] != null 
          ? '${json['parent']['firstName'] ?? ''} ${json['parent']['lastName'] ?? ''}'.trim()
          : null,
      parentPhone: json['parent']?['phone'],
      status: json['status'] ?? 'active',
      enrollmentDate: DateTime.parse(json['enrollmentDate'] ?? DateTime.now().toIso8601String()),
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'studentId': studentId,
      'className': className,
      'status': status,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'additionalInfo': additionalInfo,
    };
  }
}

class StudentStats {
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final List<ClassSummary> classSummary;
  final List<Student> recentEnrollments;

  StudentStats({
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.classSummary,
    required this.recentEnrollments,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      totalStudents: json['totalStudents'] ?? 0,
      activeStudents: json['activeStudents'] ?? 0,
      inactiveStudents: json['inactiveStudents'] ?? 0,
      classSummary: (json['classSummary'] as List?)
          ?.map((c) => ClassSummary.fromJson(c))
          .toList() ?? [],
      recentEnrollments: (json['recentEnrollments'] as List?)
          ?.map((s) => Student.fromJson(s))
          .toList() ?? [],
    );
  }
}

class ClassSummary {
  final String className;
  final int studentCount;
  final String? teacher;

  ClassSummary({
    required this.className,
    required this.studentCount,
    this.teacher,
  });

  factory ClassSummary.fromJson(Map<String, dynamic> json) {
    return ClassSummary(
      className: json['className'] ?? '',
      studentCount: json['studentCount'] ?? 0,
      teacher: json['teacher'],
    );
  }
}

// Student state classes
class StudentsState {
  final bool isLoading;
  final List<Student> students;
  final StudentStats? stats;
  final String? error;
  final String searchQuery;
  final String? selectedClass;
  final String? statusFilter;

  StudentsState({
    this.isLoading = false,
    this.students = const [],
    this.stats,
    this.error,
    this.searchQuery = '',
    this.selectedClass,
    this.statusFilter,
  });

  StudentsState copyWith({
    bool? isLoading,
    List<Student>? students,
    StudentStats? stats,
    String? error,
    String? searchQuery,
    String? selectedClass,
    String? statusFilter,
  }) {
    return StudentsState(
      isLoading: isLoading ?? this.isLoading,
      students: students ?? this.students,
      stats: stats ?? this.stats,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedClass: selectedClass ?? this.selectedClass,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Student> get filteredStudents {
    var filtered = students;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((student) =>
          student.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.studentId.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    // Apply class filter
    if (selectedClass != null && selectedClass!.isNotEmpty) {
      filtered = filtered.where((student) => student.className == selectedClass).toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      filtered = filtered.where((student) => student.status == statusFilter).toList();
    }

    return filtered;
  }
}

// Students provider
class StudentsNotifier extends StateNotifier<StudentsState> {
  final ApiService _apiService;

  StudentsNotifier(this._apiService) : super(StudentsState());

  Future<void> loadStudents() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.get('/students');
      if (response.isSuccess && response.data != null) {
        final List<dynamic> studentsJson = response.data!['students'] ?? [];
        final students = studentsJson.map((s) => Student.fromJson(s)).toList();
        
        state = state.copyWith(
          isLoading: false,
          students: students,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message ?? 'Failed to load students',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load students: $e',
      );
    }
  }

  Future<void> loadStats() async {
    try {
      final response = await _apiService.get('/students/stats');
      if (response.isSuccess && response.data != null) {
        final stats = StudentStats.fromJson(response.data!);
        state = state.copyWith(stats: stats);
      }
    } catch (e) {
      // Don't update error state for stats failure
      print('Failed to load student stats: $e');
    }
  }

  Future<bool> createStudent({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    required String studentId,
    required String classId,
    String? parentId,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final response = await _apiService.post('/students', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'studentId': studentId,
        'class': classId,
        'parent': parentId,
        'additionalInfo': additionalInfo,
      });
      
      if (response.isSuccess) {
        // Reload students to get updated data
        await loadStudents();
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to create student');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create student: $e');
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.put('/students/$studentId', data: updates);
      
      if (response.isSuccess) {
        // Update local state
        final updatedStudents = state.students.map((student) {
          if (student.id == studentId) {
            // Create updated student with new data
            final updatedData = student.toJson()..addAll(updates);
            return Student.fromJson(updatedData);
          }
          return student;
        }).toList();
        
        state = state.copyWith(students: updatedStudents);
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to update student');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update student: $e');
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      final response = await _apiService.delete('/students/$studentId');
      
      if (response.isSuccess) {
        // Remove from local state
        final updatedStudents = state.students.where((s) => s.id != studentId).toList();
        state = state.copyWith(students: updatedStudents);
        await loadStats();
        return true;
      } else {
        state = state.copyWith(error: response.message ?? 'Failed to delete student');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete student: $e');
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setClassFilter(String? className) {
    state = state.copyWith(selectedClass: className);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedClass: null,
      statusFilter: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider instances
final studentsProvider = StateNotifierProvider<StudentsNotifier, StudentsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return StudentsNotifier(apiService);
});

// Computed providers
final activeStudentsProvider = Provider<List<Student>>((ref) {
  final studentsState = ref.watch(studentsProvider);
  return studentsState.students.where((s) => s.status == 'active').toList();
});

final studentsByClassProvider = Provider<Map<String, List<Student>>>((ref) {
  final studentsState = ref.watch(studentsProvider);
  final Map<String, List<Student>> byClass = {};
  
  for (final student in studentsState.students) {
    if (!byClass.containsKey(student.className)) {
      byClass[student.className] = [];
    }
    byClass[student.className]!.add(student);
  }
  
  return byClass;
});

final studentsSearchResultsProvider = Provider<List<Student>>((ref) {
  final studentsState = ref.watch(studentsProvider);
  return studentsState.filteredStudents;
});
