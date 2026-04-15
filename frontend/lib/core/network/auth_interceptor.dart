/// "A Dio Interceptor that automatically injects the JWT token into outgoing requests."
/// "Also handles global 401 Unauthorized errors by clearing local session data."
import 'dart:ui';

import 'package:dio/dio.dart';
import 'token_provider.dart';

class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;

  /// Called when a 401 is received so the app can navigate back to login.
  VoidCallback? onUnauthorized;

  AuthInterceptor({required this.tokenProvider, this.onUnauthorized});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If we get a 401 Unauthorized, it means the token is likely expired or invalid
    if (err.response?.statusCode == 401) {
      await tokenProvider.clearToken();
      onUnauthorized?.call();
    }

    return handler.next(err);
  }
}
