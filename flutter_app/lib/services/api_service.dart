import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'https://hfa-production-a1ce.up.railway.app';
  static final ApiService _instance = ApiService._internal();
  late final Dio _dio;

  // In-memory token cache - no disk reads per request
  static String? _cachedToken;

  factory ApiService() => _instance;

  static void setToken(String? token) => _cachedToken = token;
  static void clearToken() => _cachedToken = null;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Synchronous - no async SharedPreferences read
        if (_cachedToken != null) {
          options.headers['Authorization'] = 'Bearer $_cachedToken';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(String path, {dynamic data, Options? options}) =>
      _dio.post(path, data: data, options: options);

  Future<Response> put(String path, {dynamic data, Options? options}) =>
      _dio.put(path, data: data, options: options);

  Future<Response> delete(String path, {Options? options}) =>
      _dio.delete(path, options: options);
}
