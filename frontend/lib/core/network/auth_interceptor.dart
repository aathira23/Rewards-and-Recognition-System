/// "A Dio Interceptor that automatically injects the JWT token into outgoing requests."
/// "Also handles global 401 Unauthorized errors by clearing local session data."
import 'package:dio/dio.dart';
import 'token_provider.dart';

class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;

  AuthInterceptor({required this.tokenProvider});

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
      // TODO: Provide a mechanism to navigate to login (e.g., via a global Navigator key or EventBus)
    }

    return handler.next(err);
  }
}
