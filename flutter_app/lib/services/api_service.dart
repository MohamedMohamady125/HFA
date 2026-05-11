import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  // TODO: Replace with your Railway URL after deployment (e.g. https://your-app.up.railway.app)
  static const String baseUrl = 'http://192.168.1.8:8000';
  static final ApiService _instance = ApiService._internal();
  late final Dio _dio;

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('authUser');
        if (stored != null) {
          final user = jsonDecode(stored);
          if (user['token'] != null) {
            options.headers['Authorization'] = 'Bearer ${user['token']}';
          }
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(String path, {dynamic data, Options? options}) =>
      _dio.post(path, data: data, options: options);

  Future<Response> put(String path, {dynamic data, Options? options}) =>
      _dio.put(path, data: data, options: options);

  Future<Response> delete(String path, {Options? options}) =>
      _dio.delete(path, options: options);
}
