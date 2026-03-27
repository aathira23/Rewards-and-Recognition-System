/// "Interface for the Remote Data Source responsible for Authentication."
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_model.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  /// Calls the backend login endpoint.
  /// Throws [ServerException] or [NetworkException] on error.
  Future<AuthModel> login({
    required String email,
    required String password,
  });

  /// Dev helper: validates a raw Styria Bearer token via the backend and
  /// returns it as an AuthModel so it can be stored and used normally.
  Future<AuthModel> tokenLogin({required String token});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    // Backend OAuth2PasswordRequestForm expects 'username' and 'password'
    // in 'application/x-www-form-urlencoded' format.
    final data = {
      'username': email,
      'password': password,
    };

    final response = await client.post(
      ApiConstants.login,
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    // Map the success response to our AuthModel
    // Backend wraps data inside 'responseData', unwrapped to 'data' by interceptor
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthModel.fromJson(response.data['data']);
    } else {
      // Exceptions are usually handled inside ApiClient._handleError,
      // but we add a fallback for extra safety.
      throw Exception(
          'Failed to login: Unexpected status code ${response.statusCode}');
    }
  }

  @override
  Future<AuthModel> tokenLogin({required String token}) async {
    final response = await client.post(
      ApiConstants.tokenLogin,
      data: {'token': token},
      options: Options(contentType: Headers.jsonContentType),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthModel.fromJson(response.data['data']);
    } else {
      throw Exception(
          'Token login failed: Unexpected status code ${response.statusCode}');
    }
  }
}
