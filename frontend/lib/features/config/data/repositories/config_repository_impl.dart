import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../datasources/config_remote_data_source.dart';
import '../../domain/entities/system_config_entity.dart';
import '../../domain/entities/points_rule_entity.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  final ConfigRemoteDataSource remoteDataSource;

  ConfigRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SystemConfigEntity>>> getConfigs() async {
    try {
      final models = await remoteDataSource.getConfigs();
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PointsRuleEntity>>> getPointsRules() async {
    try {
      final models = await remoteDataSource.getPointsRules();
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateConfig(String key, String value) async {
    try {
      await remoteDataSource.updateConfig(key, value);
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
