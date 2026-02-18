import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/recognition_entity.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../domain/repositories/recognitions_repository.dart';
import '../datasources/recognitions_remote_data_source.dart';

class RecognitionsRepositoryImpl implements RecognitionsRepository {
  final RecognitionsRemoteDataSource remoteDataSource;

  RecognitionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<BadgeEntity>>> getBadges() async {
    try {
      final badges = await remoteDataSource.getBadges();
      return Right(badges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecognitionEntity>>> getRecognitionFeed() async {
    try {
      final feed = await remoteDataSource.getRecognitionFeed();
      return Right(feed);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RecognitionEntity>> sendRecognition({
    required int receiverId,
    required int badgeId,
    String? message,
  }) async {
    try {
      final recognition = await remoteDataSource.sendRecognition(
        receiverId: receiverId,
        badgeId: badgeId,
        message: message,
      );
      return Right(recognition);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppreciationStatsEntity>>
      getAppreciationStats() async {
    try {
      final stats = await remoteDataSource.getAppreciationStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
