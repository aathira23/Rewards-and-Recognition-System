/// Web-safe TokenProvider / AuthLocalDataSource that uses shared_preferences
/// instead of flutter_secure_storage (which requires native platform support).
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart';

class WebTokenProviderImpl implements AuthLocalDataSource {
  static const _tokenKey = 'JWT_ACCESS_TOKEN';

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}
