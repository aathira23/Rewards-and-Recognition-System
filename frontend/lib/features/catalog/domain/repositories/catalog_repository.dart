import '../entities/reward_entity.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class CatalogRepository {
  Future<Either<Failure, List<RewardEntity>>> getCatalogItems();
  Future<Either<Failure, bool>> redeemItem(int rewardId);
  Future<Either<Failure, Map<String, List>>> getHistory();
  Future<Either<Failure, bool>> submitConversionRequest(
      int points, String type);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPointsRules();
}
