import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/reward_model.dart';
import '../models/redemption_model.dart';
import '../models/points_conversion_model.dart';

abstract class CatalogRemoteDataSource {
  Future<(int, List<RewardModel>)> getCatalogItems(
      {int page = 1, int perPage = 20});
  Future<bool> redeemItem(int rewardId);
  Future<Map<String, List>> getHistory();
  Future<bool> submitConversionRequest(int points, String type);
  Future<List<Map<String, dynamic>>> getPointsRules();
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final ApiClient client;

  CatalogRemoteDataSourceImpl({required this.client});

  @override
  Future<(int, List<RewardModel>)> getCatalogItems(
      {int page = 1, int perPage = 20}) async {
    final response = await client.get(
      ApiConstants.catalogItems,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> wrapper = response.data['data'];
      final List dataList = wrapper['items'] ?? [];
      final int total = (wrapper['total'] as num?)?.toInt() ?? dataList.length;
      final items = dataList.map((json) => RewardModel.fromJson(json)).toList();
      return (total, items);
    } else {
      throw Exception('Failed to load catalog');
    }
  }

  @override
  Future<bool> redeemItem(int rewardId) async {
    final response = await client.post(ApiConstants.catalogRedeem, data: {
      'reward_id': rewardId,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<Map<String, List>> getHistory() async {
    final response = await client.get(ApiConstants.catalogHistory);
    if (response.statusCode == 200) {
      final rawData = response.data['data'];
      final List redemptions =
          (rawData is Map ? rawData['redemptions'] : rawData) as List? ?? [];
      final List conversions =
          (rawData is Map ? rawData['conversions'] : []) as List? ?? [];

      return {
        'redemptions':
            redemptions.map((e) => RedemptionModel.fromJson(e)).toList(),
        'conversions':
            conversions.map((e) => PointsConversionModel.fromJson(e)).toList(),
      };
    } else {
      throw Exception('Failed to load history (${response.statusCode})');
    }
  }

  @override
  Future<bool> submitConversionRequest(int points, String type) async {
    final response = await client.post(ApiConstants.pointsConvert, data: {
      'points_converted': points,
      'conversion_type': type,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<List<Map<String, dynamic>>> getPointsRules() async {
    final response = await client.get(ApiConstants.pointsRules);
    if (response.statusCode == 200) {
      final List data = response.data['data'];
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
