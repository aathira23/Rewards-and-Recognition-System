import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/badge_model.dart';
import '../models/recognition_model.dart';
import '../models/appreciation_stats_model.dart';

abstract class RecognitionsRemoteDataSource {
  Future<List<BadgeModel>> getBadges();
  Future<List<RecognitionModel>> getRecognitionFeed();
  Future<RecognitionModel> sendRecognition({
    required int receiverId,
    required int badgeId,
    String? message,
  });
  Future<AppreciationStatsModel> getAppreciationStats();
}

class RecognitionsRemoteDataSourceImpl implements RecognitionsRemoteDataSource {
  final ApiClient client;

  RecognitionsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<BadgeModel>> getBadges() async {
    final response = await client.get(ApiConstants.badges);
    final List data = response.data['data'];
    return data.map((json) => BadgeModel.fromJson(json)).toList();
  }

  @override
  Future<List<RecognitionModel>> getRecognitionFeed() async {
    final response = await client.get(ApiConstants.recognitionFeed);
    final List data = response.data['data'];
    return data.map((json) => RecognitionModel.fromJson(json)).toList();
  }

  @override
  Future<RecognitionModel> sendRecognition({
    required int receiverId,
    required int badgeId,
    String? message,
  }) async {
    final response = await client.post(
      ApiConstants.sendRecognition,
      data: {
        'receiver_id': receiverId,
        'badge_id': badgeId,
        'message': message,
      },
    );
    return RecognitionModel.fromJson(response.data['data']);
  }

  @override
  Future<AppreciationStatsModel> getAppreciationStats() async {
    try {
      final response = await client.get(ApiConstants.recognitionOverview);
      // Backend wraps response in { "data": { ... } }
      final rawData = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      final Map<String, dynamic> statsMap =
          (rawData as Map<String, dynamic>?) ?? {};
      return AppreciationStatsModel.fromJson(statsMap);
    } catch (_) {
      // Return empty stats on error so the rest of the page still loads
      return AppreciationStatsModel.empty();
    }
  }
}
