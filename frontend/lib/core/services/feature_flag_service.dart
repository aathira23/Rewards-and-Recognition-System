import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Lightweight service to fetch feature flags from the backend.
/// Does not go through the full use-case / repository chain because
/// feature flags are cross-cutting and not feature-specific.
class FeatureFlagService {
  final ApiClient _client;

  FeatureFlagService({required ApiClient client}) : _client = client;

  /// Returns the map of feature flags, e.g. {'conversion_enabled': true}.
  Future<Map<String, bool>> getAll() async {
    try {
      final response = await _client.get(ApiConstants.featureFlags);
      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return data.map((k, v) => MapEntry(k, v == true || v == 'true'));
      }
    } catch (_) {
      // Fail-open: default to enabled if we can't reach the server
    }
    return {'conversion_enabled': true};
  }

  /// Convenience: check a single flag.
  Future<bool> isEnabled(String flag) async {
    final flags = await getAll();
    return flags[flag] ?? true;
  }
}
