/// "A robust networking client built on Dio to handle all API communications."
/// "Includes centralized error handling and placeholders for authentication logic."

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/browser.dart' show BrowserHttpClientAdapter;
import 'auth_interceptor.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio, AuthInterceptor? authInterceptor})
      : _dio = dio ?? Dio() {
    _applyBaseOptions();
    // Use browser HTTP adapter when running on web
    if (kIsWeb) {
      _dio.httpClientAdapter = BrowserHttpClientAdapter();
    }

    if (authInterceptor != null) {
      _dio.interceptors.add(authInterceptor);
    }
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
