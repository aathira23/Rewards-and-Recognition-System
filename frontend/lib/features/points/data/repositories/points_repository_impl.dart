import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/points_remote_data_source.dart';
import '../../domain/entities/points_summary_entity.dart';
import '../../domain/entities/point_transaction_entity.dart';
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
  Future<Either<Failure, List<PointTransactionEntity>>> getPointsHistory(
      {int page = 1}) async {
    try {
      final history = await remoteDataSource.getPointsHistory(page: page);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
