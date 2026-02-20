import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/user_mgmt_repository.dart';
import '../datasources/user_mgmt_remote_data_source.dart';

class UserMgmtRepositoryImpl implements UserMgmtRepository {
  final UserMgmtRemoteDataSource remoteDataSource;
  UserMgmtRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUsers() async {
    try {
      final result = await remoteDataSource.fetchUsers();
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
  Future<Either<Failure, void>> createUser(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.createUser(data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUser(
      int id, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateUser(id, data);
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
