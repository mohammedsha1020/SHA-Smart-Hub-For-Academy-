import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../network/dio_interceptor.dart';

// Singleton instances
late SharedPreferences _prefs;
late ApiClient _apiClient;

Future<void> configureDependencies() async {
  // Initialize SharedPreferences
  _prefs = await SharedPreferences.getInstance();
  
  // Initialize Dio
  final dio = Dio();
  
  // Add interceptors
  dio.interceptors.add(AuthInterceptor(_prefs));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (object) => print(object),
  ));
  
  // Initialize API client
  _apiClient = ApiClient(dio);
}

// Getters for dependencies
SharedPreferences get prefs => _prefs;
ApiClient get apiClient => _apiClient;
