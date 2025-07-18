import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  
  // API base URL - update this to your backend URL
  static const String baseUrl = 'http://localhost:5000/api';
  
  ApiClient(this._dio) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }
  
  // Auth endpoints
  Future<Response> login(Map<String, dynamic> data) async {
    return await _dio.post('/auth/login', data: data);
  }
  
  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/auth/register', data: data);
  }
  
  Future<Response> logout() async {
    return await _dio.post('/auth/logout');
  }
  
  Future<Response> refreshToken() async {
    return await _dio.post('/auth/refresh');
  }
  
  // Finance endpoints
  Future<Response> getFees({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/finance/fees', queryParameters: queryParams);
  }
  
  Future<Response> getFinanceDashboard({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/finance/dashboard', queryParameters: queryParams);
  }
  
  Future<Response> createFee(Map<String, dynamic> data) async {
    return await _dio.post('/finance/fees', data: data);
  }
  
  Future<Response> addPayment(String feeId, Map<String, dynamic> data) async {
    return await _dio.post('/finance/fees/$feeId/payment', data: data);
  }
  
  Future<Response> getFinanceReports({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/finance/reports', queryParameters: queryParams);
  }
  
  // Students endpoints
  Future<Response> getStudents({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/students', queryParameters: queryParams);
  }
  
  Future<Response> getStudent(String studentId) async {
    return await _dio.get('/students/$studentId');
  }
  
  Future<Response> createStudent(Map<String, dynamic> data) async {
    return await _dio.post('/students', data: data);
  }
  
  Future<Response> updateStudent(String studentId, Map<String, dynamic> data) async {
    return await _dio.put('/students/$studentId', data: data);
  }
  
  Future<Response> getStudentFees(String studentId, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/students/$studentId/fees', queryParameters: queryParams);
  }
  
  Future<Response> getStudentAttendance(String studentId, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/students/$studentId/attendance', queryParameters: queryParams);
  }
  
  // Attendance endpoints
  Future<Response> getAttendance({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/attendance', queryParameters: queryParams);
  }
  
  Future<Response> markAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance', data: data);
  }
  
  Future<Response> markBulkAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance/bulk', data: data);
  }
  
  Future<Response> getAttendanceStatistics({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/attendance/statistics', queryParameters: queryParams);
  }
  
  // Announcements endpoints
  Future<Response> getAnnouncements({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/announcements', queryParameters: queryParams);
  }
  
  Future<Response> createAnnouncement(Map<String, dynamic> data) async {
    return await _dio.post('/announcements', data: data);
  }
  
  Future<Response> updateAnnouncement(String id, Map<String, dynamic> data) async {
    return await _dio.put('/announcements/$id', data: data);
  }
  
  Future<Response> markAnnouncementAsRead(String id) async {
    return await _dio.post('/announcements/$id/read');
  }
  
  Future<Response> deleteAnnouncement(String id) async {
    return await _dio.delete('/announcements/$id');
  }
  
  // Timetable endpoints
  Future<Response> getTimetables({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/timetables', queryParameters: queryParams);
  }
  
  Future<Response> getTeacherSchedule(String teacherId, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/timetables/teacher/$teacherId', queryParameters: queryParams);
  }
  
  Future<Response> createTimetable(Map<String, dynamic> data) async {
    return await _dio.post('/timetables', data: data);
  }
  
  Future<Response> updateTimetable(String id, Map<String, dynamic> data) async {
    return await _dio.put('/timetables/$id', data: data);
  }
  
  Future<Response> publishTimetable(String id) async {
    return await _dio.put('/timetables/$id/publish');
  }
  
  // Notifications endpoints
  Future<Response> getNotifications({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/notifications', queryParameters: queryParams);
  }
  
  Future<Response> createNotification(Map<String, dynamic> data) async {
    return await _dio.post('/notifications', data: data);
  }
  
  Future<Response> markNotificationAsRead(String id) async {
    return await _dio.put('/notifications/$id/read');
  }
  
  Future<Response> archiveNotification(String id) async {
    return await _dio.put('/notifications/$id/archive');
  }
  
  Future<Response> markAllNotificationsAsRead() async {
    return await _dio.put('/notifications/mark-all-read');
  }
  
  Future<Response> sendBulkNotifications(Map<String, dynamic> data) async {
    return await _dio.post('/notifications/bulk', data: data);
  }
  
  // Users endpoints
  Future<Response> getUsers({Map<String, dynamic>? queryParams}) async {
    return await _dio.get('/users', queryParameters: queryParams);
  }
  
  Future<Response> getUser(String userId) async {
    return await _dio.get('/users/$userId');
  }
  
  Future<Response> updateUser(String userId, Map<String, dynamic> data) async {
    return await _dio.put('/users/$userId', data: data);
  }
  
  Future<Response> deleteUser(String userId, {bool permanent = false}) async {
    return await _dio.delete('/users/$userId', queryParameters: {'permanent': permanent});
  }
  
  Future<Response> getStudentsByClass(String classId) async {
    return await _dio.get('/users/students/by-class/$classId');
  }
}
