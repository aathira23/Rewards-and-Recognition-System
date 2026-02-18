import 'package:dio/dio.dart';
import '../models/reward_model.dart';
import '../models/redemption_model.dart';
import '../models/points_conversion_model.dart';

abstract class CatalogRemoteDataSource {
  Future<List<RewardModel>> getCatalogItems();
  Future<bool> redeemItem(int rewardId);
  Future<Map<String, List>> getHistory();
  Future<bool> submitConversionRequest(int points, String type);
  Future<List<Map<String, dynamic>>> getPointsRules();
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final Dio dio;

  CatalogRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<RewardModel>> getCatalogItems() async {
    final response = await dio.get('/catalog/items');
    if (response.statusCode == 200) {
      final List dataList = response.data['data'];
      return dataList.map((json) => RewardModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load catalog');
    }
  }

  @override
  Future<bool> redeemItem(int rewardId) async {
    final response = await dio.post('/catalog/redeem', data: {
      'reward_id': rewardId,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<Map<String, List>> getHistory() async {
    try {
      final response = await dio.get('/catalog/history');
      if (response.statusCode == 200) {
        final rawData = response.data['data'];
        // Backend may return a flat list of redemptions OR a map with both
        // lists. Handle both shapes defensively.
        final List redemptions =
            (rawData is Map ? rawData['redemptions'] : rawData) as List? ?? [];
        final List conversions =
            (rawData is Map ? rawData['conversions'] : []) as List? ?? [];

        return {
          'redemptions':
              redemptions.map((e) => RedemptionModel.fromJson(e)).toList(),
          'conversions': conversions
              .map((e) => PointsConversionModel.fromJson(e))
              .toList(),
        };
      } else {
        throw Exception('Failed to load history (${response.statusCode})');
      }
    } catch (_) {
      // On any network / parse error return empty history instead of crashing
      return {'redemptions': [], 'conversions': []};
    }
  }

  @override
  Future<bool> submitConversionRequest(int points, String type) async {
    final response = await dio.post('/points/convert', data: {
      'points_converted': points,
      'conversion_type': type,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  @override
  Future<List<Map<String, dynamic>>> getPointsRules() async {
    final response = await dio.get('/points/rules');
    if (response.statusCode == 200) {
      final List data = response.data['data'];
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }
}
