import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';
import '../repositories/hr_config_repository.dart';

class ToggleHrConfigItemUseCase
    implements UseCase<void, ToggleHrConfigItemParams> {
  final HrConfigRepository repository;
  const ToggleHrConfigItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleHrConfigItemParams params) {
    switch (params.entityType) {
      case HrConfigEntityType.awardType:
        return repository.toggleAwardType(params.id, params.newActive);
      case HrConfigEntityType.badge:
        return repository.toggleBadge(params.id, params.newActive);
      case HrConfigEntityType.reward:
        return repository.toggleReward(params.id, params.newActive);
      case HrConfigEntityType.policyRule:
        // Policy rules don't have a dedicated toggle endpoint;
        // use updatePolicyRule with is_active flag.
        return repository
            .updatePolicyRule(params.id, {'is_active': params.newActive});
    }
  }
}

class ToggleHrConfigItemParams extends Equatable {
  final HrConfigEntityType entityType;
  final int id;
  final bool newActive;

  const ToggleHrConfigItemParams({
    required this.entityType,
    required this.id,
    required this.newActive,
  });

  @override
  List<Object?> get props => [entityType, id, newActive];
}
