import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/system_config_model.dart';
import '../models/points_rule_model.dart';

abstract class ConfigRemoteDataSource {
  Future<List<SystemConfigModel>> getConfigs();
  Future<List<PointsRuleModel>> getPointsRules();
  Future<void> updateConfig(String key, String value);
}

class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  final ApiClient client;

  ConfigRemoteDataSourceImpl({required this.client});

  @override
  Future<List<SystemConfigModel>> getConfigs() async {
    final response = await client.get(ApiConstants.systemConfig);
    final data = response.data['data'] ?? [];
    if (data is List) {
      return data
          .map((e) => SystemConfigModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<PointsRuleModel>> getPointsRules() async {
    final response = await client.get(ApiConstants.pointsRules);
    final data = response.data['data'] ?? response.data ?? [];
    if (data is List) {
      return data
          .map((e) => PointsRuleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> updateConfig(String key, String value) async {
    await client.patch(
      '${ApiConstants.systemConfig}$key',
      data: {'value': value},
    );
  }
}
