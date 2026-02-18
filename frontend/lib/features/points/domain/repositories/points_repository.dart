import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/points_summary_entity.dart';
import '../entities/point_transaction_entity.dart';

abstract class PointsRepository {
  Future<Either<Failure, PointsSummaryEntity>> getPointsSummary();
  Future<Either<Failure, List<PointTransactionEntity>>> getPointsHistory(
      {int page = 1});
}
