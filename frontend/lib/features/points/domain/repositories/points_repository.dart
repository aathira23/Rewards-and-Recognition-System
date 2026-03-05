import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/points_summary_entity.dart';
import '../entities/point_transaction_entity.dart';
import '../entities/leaderboard_entry_entity.dart';

abstract class PointsRepository {
  Future<Either<Failure, PointsSummaryEntity>> getPointsSummary();
  Future<Either<Failure, (int, List<PointTransactionEntity>)>>
      getPointsHistory({
    int page = 1,
    int perPage = kDefaultPageSize,
    String? category,
    String? startDate,
    String? endDate,
    String? walletType,
  });
  Future<Either<Failure, List<LeaderboardEntryEntity>>> getLeaderboard(
      {String period = 'MONTHLY'});
}
