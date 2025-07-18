import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  
  AuthInterceptor(this._prefs);
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add auth token to request headers
    final token = _prefs.getString('auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add content type
    options.headers['Content-Type'] = 'application/json';
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle successful responses
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle authentication errors
    if (err.response?.statusCode == 401) {
      // Token expired or invalid - clear stored token
      _prefs.remove('auth_token');
      _prefs.remove('user_data');
      
      // You might want to navigate to login page here
      // Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
    
    handler.next(err);
  }
}
