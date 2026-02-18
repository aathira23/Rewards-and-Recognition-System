import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/token_provider.dart';
import '../../../../core/errors/exceptions.dart';

abstract class AuthLocalDataSource implements TokenProvider {
  /// Persists the JWT token to secure storage.
  Future<void> saveToken(String token);

  /// Retrieves the cached JWT token.
  /// Returns null if no token is found.
  Future<String?> getToken();

  /// Deletes the token from storage (Logout).
  Future<void> clearToken();

  /// Checks if a token exists in storage.
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  static const _tokenKey = 'JWT_ACCESS_TOKEN';

  @override
  Future<void> saveToken(String token) async {
    try {
      await secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return (await secureStorage.read(key: _tokenKey))?.trim();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<bool> hasToken() async {
    try {
      final token = await secureStorage.read(key: _tokenKey);
      return token != null;
    } catch (e) {
      throw CacheException();
    }
  }
}
