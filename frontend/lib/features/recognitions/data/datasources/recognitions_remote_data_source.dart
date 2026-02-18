import 'dart:convert';
import 'package:dio/dio.dart';
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
  final Dio dio;

  RecognitionsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<BadgeModel>> getBadges() async {
    final response = await dio.get(ApiConstants.badges);
    final List data = response.data['data'];
    return data.map((json) => BadgeModel.fromJson(json)).toList();
  }

  @override
  Future<List<RecognitionModel>> getRecognitionFeed() async {
    final response = await dio.get(ApiConstants.recognitionFeed);
    final List data = response.data['data'];
    return data.map((json) => RecognitionModel.fromJson(json)).toList();
  }

  @override
  Future<RecognitionModel> sendRecognition({
    required int receiverId,
    required int badgeId,
    String? message,
  }) async {
    final response = await dio.post(
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
    // TODO: Use actual endpoint once verified (using mock for now if needed, or implement endpoint constant)
    // Assuming endpoint exists: /recognitions/stats or /recognitions/me/overview
    // Based on previous turn: /recognitions/me/overview
    final response = await dio.get('recognitions/me/overview');
    return AppreciationStatsModel.fromJson(json.decode(response.data));
  }
}
