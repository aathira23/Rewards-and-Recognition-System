import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/recognition_entity.dart';
import '../../domain/entities/appreciation_stats_entity.dart';

abstract class RecognitionsRepository {
  Future<Either<Failure, List<BadgeEntity>>> getBadges();
  Future<Either<Failure, List<RecognitionEntity>>> getRecognitionFeed();
  Future<Either<Failure, RecognitionEntity>> sendRecognition({
    required int receiverId,
    required int badgeId,
    String? message,
  });
  Future<Either<Failure, AppreciationStatsEntity>> getAppreciationStats();
}
