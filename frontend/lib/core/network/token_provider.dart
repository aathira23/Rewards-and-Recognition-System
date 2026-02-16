/// "Abstract interface for providing authentication tokens."
/// "Used by the networking layer to decouple from specific auth implementations."
abstract class TokenProvider {
  Future<String?> getToken();
  Future<void> clearToken();
}
