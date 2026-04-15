import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/hr_approvals_remote_data_source.dart';
import '../../domain/repositories/hr_approvals_repository.dart';

class HrApprovalsRepositoryImpl implements HrApprovalsRepository {
  final HrApprovalsRemoteDataSource remoteDataSource;
  const HrApprovalsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchNominations() async {
    try {
      final data = await remoteDataSource.fetchNominations();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> actionNomination(
      int id, String action, String? comments) async {
    try {
      await remoteDataSource.actionNomination(id, action, comments);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchConversions() async {
    try {
      final data = await remoteDataSource.fetchConversions();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> actionConversion(int id, String action) async {
    try {
      await remoteDataSource.actionConversion(id, action);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchManagers() async {
    try {
      final data = await remoteDataSource.fetchManagers();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> allocateBudget(
      int managerId, int points) async {
    try {
      await remoteDataSource.allocateBudget(managerId, points);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> bulkAllocateBudget(
      int points, int? departmentId, String? roleFilter) async {
    try {
      final count = await remoteDataSource.bulkAllocateBudget(
          points, departmentId, roleFilter);
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      fetchAllEmployees() async {
    try {
      final data = await remoteDataSource.fetchAllEmployees();
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> triggerLifeEvent(
      int userId, String celebrationType) async {
    try {
      final result =
          await remoteDataSource.triggerLifeEvent(userId, celebrationType);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
