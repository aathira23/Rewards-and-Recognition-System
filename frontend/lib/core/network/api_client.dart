/// "A robust networking client built on Dio to handle all API communications."
/// "Includes centralized error handling and placeholders for authentication logic."

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _applyBaseOptions();
    _initializeInterceptors();
  }

  void _applyBaseOptions() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout =
        const Duration(milliseconds: ApiConstants.connectTimeout);
    _dio.options.receiveTimeout =
        const Duration(milliseconds: ApiConstants.receiveTimeout);
    _dio.options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // TODO: Intercept requests to add Authentication Token (JWT)
          // 1. Fetch token from secure storage (e.g., flutter_secure_storage)
          // 2. If token exists, add to header: options.headers['Authorization'] = 'Bearer $token'
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // TODO: Handle Global Token Expiration
          // 1. Check if e.response?.statusCode == 401
          // 2. If unauthorized, trigger clear session and redirect to login
          return handler.next(e);
        },
      ),
    );

    // Optional: Add logging interceptor for development
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  /// REST GET Method
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// REST POST Method
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// REST PATCH Method
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// REST DELETE Method
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// "Centralized error handling to convert DioException into clean Server/Network Exceptions."
  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(
          message: 'Connection timed out. Please check your internet.');
    }

    if (e.response != null) {
      final int statusCode = e.response!.statusCode ?? 500;
      final dynamic data = e.response?.data;
      String message = 'Something went wrong on the server.';

      // Try to extract error message from backend response if available
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else if (data is Map && data.containsKey('detail')) {
        // Handle FastAPI detail messages
        message = data['detail'].toString();
      }

      if (statusCode == 401) {
        return UnauthorizedException(message: message);
      }

      return ServerException(
        message: message,
        statusCode: statusCode,
      );
    }

    return ServerException(
        message: 'An unexpected error occurred: ${e.message}');
  }
}
