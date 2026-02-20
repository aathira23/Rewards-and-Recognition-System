import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/system_config_entity.dart';
import '../entities/points_rule_entity.dart';

abstract class ConfigRepository {
  Future<Either<Failure, List<SystemConfigEntity>>> getConfigs();
  Future<Either<Failure, List<PointsRuleEntity>>> getPointsRules();
  Future<Either<Failure, void>> updateConfig(String key, String value);
}
