/// "Data layer implementation of the AuthRepository."
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authModel = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Persist token upon successful login
      await localDataSource.saveToken(authModel.token);

      return Right(authModel);
    } on UnauthorizedException catch (e) {
      // 401 from backend — wrong email or password
      final raw = e.message.toLowerCase();
      final friendly = raw.contains('password')
          ? 'Incorrect password. Please try again.'
          : raw.contains('user') ||
                  raw.contains('email') ||
                  raw.contains('not found')
              ? 'No account found with that email.'
              : 'Incorrect email or password. Please try again.';
      return Left(ServerFailure(friendly));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException {
      return const Left(CacheFailure('Failed to cache login credentials'));
    } catch (e) {
      return Left(ServerFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearToken();
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Failed to clear local auth data'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await localDataSource.hasToken();
    } catch (_) {
      return false;
    }
  }
}
