import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/celebration_entity.dart';
import '../../domain/repositories/celebrations_repository.dart';
import '../datasources/celebrations_remote_data_source.dart';

class CelebrationsRepositoryImpl implements CelebrationsRepository {
  final CelebrationsRemoteDataSource remoteDataSource;
  CelebrationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CelebrationEntity>>> getUpcoming(
      {int days = 30}) async {
    try {
      final result = await remoteDataSource.getUpcoming(days: days);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CelebrationEntity>>> getHistory() async {
    try {
      final result = await remoteDataSource.getHistory();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> processToday() async {
    try {
      await remoteDataSource.processToday();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
