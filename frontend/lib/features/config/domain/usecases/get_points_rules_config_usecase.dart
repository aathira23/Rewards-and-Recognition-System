import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/points_rule_entity.dart';
import '../repositories/config_repository.dart';

class GetPointsRulesConfigUseCase
    implements UseCase<List<PointsRuleEntity>, NoParams> {
  final ConfigRepository repository;

  GetPointsRulesConfigUseCase(this.repository);

  @override
  Future<Either<Failure, List<PointsRuleEntity>>> call(NoParams params) {
    return repository.getPointsRules();
  }
}
