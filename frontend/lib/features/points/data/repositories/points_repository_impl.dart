import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/points_remote_data_source.dart';
import '../../domain/entities/points_summary_entity.dart';
import '../../domain/entities/point_transaction_entity.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  final PointsRemoteDataSource remoteDataSource;

  PointsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PointsSummaryEntity>> getPointsSummary() async {
    try {
      final summary = await remoteDataSource.getPointsSummary();
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (int, List<PointTransactionEntity>)>>
      getPointsHistory({
    int page = 1,
    int perPage = kDefaultPageSize,
    String? category,
    String? startDate,
    String? endDate,
    String? walletType,
  }) async {
    try {
      final (total, models) = await remoteDataSource.getPointsHistory(
        page: page,
        perPage: perPage,
        category: category,
        startDate: startDate,
        endDate: endDate,
        walletType: walletType,
      );
      return Right((total, List<PointTransactionEntity>.from(models)));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard(
      {String period = 'MONTHLY'}) async {
    try {
      final entries = await remoteDataSource.getLeaderboard(period: period);
      final leaderboard = entries
          .map((e) => LeaderboardEntryEntity(
                userId: (e['user_id'] as num).toInt(),
                name: e['name']?.toString() ?? 'Unknown',
                departmentName: e['department_name']?.toString(),
                rank: (e['rank'] as num).toInt(),
                score: (e['score'] as num).toInt(),
              ))
          .toList();
      return Right(leaderboard);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
