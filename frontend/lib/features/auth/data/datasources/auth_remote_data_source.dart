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
    // ApiClient success returns dynamic data inside response.data
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthModel.fromJson(response.data);
    } else {
      // Exceptions are usually handled inside ApiClient._handleError,
      // but we add a fallback for extra safety.
      throw Exception(
          'Failed to login: Unexpected status code ${response.statusCode}');
    }
  }
}
