import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/reward_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource remoteDataSource;

  CatalogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RewardEntity>>> getCatalogItems() async {
    try {
      final items = await remoteDataSource.getCatalogItems();
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> redeemItem(int rewardId) async {
    try {
      final success = await remoteDataSource.redeemItem(rewardId);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, List>>> getHistory() async {
    try {
      final history = await remoteDataSource.getHistory();
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitConversionRequest(
      int points, String type) async {
    try {
      final success =
          await remoteDataSource.submitConversionRequest(points, type);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPointsRules() async {
    try {
      final rules = await remoteDataSource.getPointsRules();
      return Right(rules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
