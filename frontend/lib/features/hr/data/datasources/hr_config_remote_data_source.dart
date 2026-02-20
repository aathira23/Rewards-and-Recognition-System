import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';

/// Aggregate data returned by [loadAll].
class HrConfigData {
  final List<Map<String, dynamic>> awardTypes;
  final List<Map<String, dynamic>> badges;
  final List<Map<String, dynamic>> rewards;
  final List<Map<String, dynamic>> policies;
  final List<Map<String, dynamic>> configs;

  const HrConfigData({
    required this.awardTypes,
    required this.badges,
    required this.rewards,
    required this.policies,
    required this.configs,
  });
}

/// Entity type discriminator used across save / toggle operations.
enum HrConfigEntityType { awardType, badge, reward, policyRule }

abstract class HrConfigRemoteDataSource {
  /// Fetches all five config data sets in parallel.
  Future<HrConfigData> loadAll();

  // ── Award Types ──────────────────────────────────────────────────
  Future<void> createAwardType(Map<String, dynamic> data);
  Future<void> updateAwardType(int id, Map<String, dynamic> data);
  Future<void> toggleAwardType(int id, bool newActive);

  // ── Badges ───────────────────────────────────────────────────────
  Future<void> createBadge(Map<String, dynamic> data);
  Future<void> updateBadge(int id, Map<String, dynamic> data);
  Future<void> toggleBadge(int id, bool newActive);

  // ── Rewards Catalog ──────────────────────────────────────────────
  Future<void> createReward(Map<String, dynamic> data);
  Future<void> updateReward(int id, Map<String, dynamic> data);
  Future<void> toggleReward(int id, bool newActive);

  // ── Points Policy Rules ──────────────────────────────────────────
  Future<void> createPolicyRule(Map<String, dynamic> data);
  Future<void> updatePolicyRule(int id, Map<String, dynamic> data);

  // ── System Config ────────────────────────────────────────────────
  Future<void> updateConfigSetting(String key, String value);
}

class HrConfigRemoteDataSourceImpl implements HrConfigRemoteDataSource {
  final ApiClient client;
  const HrConfigRemoteDataSourceImpl({required this.client});

  // ─── helpers ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _extractList(dynamic body) {
    final data = body is Map ? (body['data'] ?? []) : body;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return <Map<String, dynamic>>[];
  }

  // ─── loadAll ─────────────────────────────────────────────────────
  @override
  Future<HrConfigData> loadAll() async {
    try {
      final results = await Future.wait([
        client.get(ApiConstants.awardTypes),
        client.get(ApiConstants.badges),
        client.get(ApiConstants.catalogItems),
        client.get(ApiConstants.pointsRules),
        client.get(ApiConstants.systemConfig),
      ]);
      return HrConfigData(
        awardTypes: _extractList(results[0].data),
        badges: _extractList(results[1].data),
        rewards: _extractList(results[2].data),
        policies: _extractList(results[3].data),
        configs: _extractList(results[4].data),
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ─── Award Types ─────────────────────────────────────────────────
  @override
  Future<void> createAwardType(Map<String, dynamic> data) async {
    try {
      await client.post(ApiConstants.awardTypes, data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateAwardType(int id, Map<String, dynamic> data) async {
    try {
      await client.put('${ApiConstants.awardTypes}types/$id', data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> toggleAwardType(int id, bool newActive) async {
    try {
      await client.put('${ApiConstants.awardTypes}types/$id',
          data: {'is_active': newActive});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ─── Badges ──────────────────────────────────────────────────────
  @override
  Future<void> createBadge(Map<String, dynamic> data) async {
    try {
      await client.post(ApiConstants.badges, data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateBadge(int id, Map<String, dynamic> data) async {
    try {
      await client.put('${ApiConstants.badges}/$id', data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> toggleBadge(int id, bool newActive) async {
    try {
      await client
          .put('${ApiConstants.badges}/$id', data: {'is_active': newActive});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ─── Rewards Catalog ─────────────────────────────────────────────
  @override
  Future<void> createReward(Map<String, dynamic> data) async {
    try {
      await client.post(ApiConstants.catalogItems, data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateReward(int id, Map<String, dynamic> data) async {
    try {
      await client.put('${ApiConstants.catalogItems}/$id', data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> toggleReward(int id, bool newActive) async {
    try {
      await client.put('${ApiConstants.catalogItems}/$id',
          data: {'is_active': newActive});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ─── Points Policy Rules ─────────────────────────────────────────
  @override
  Future<void> createPolicyRule(Map<String, dynamic> data) async {
    try {
      await client.post(ApiConstants.pointsRules, data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updatePolicyRule(int id, Map<String, dynamic> data) async {
    try {
      await client.put('${ApiConstants.pointsRules}/$id', data: data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ─── System Config ───────────────────────────────────────────────
  @override
  Future<void> updateConfigSetting(String key, String value) async {
    try {
      await client
          .put('${ApiConstants.systemConfig}$key', data: {'value': value});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
