import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';
import '../repositories/hr_config_repository.dart';

class SaveHrConfigItemUseCase implements UseCase<void, SaveHrConfigItemParams> {
  final HrConfigRepository repository;
  const SaveHrConfigItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveHrConfigItemParams params) {
    final id = params.id;
    switch (params.entityType) {
      case HrConfigEntityType.awardType:
        return id != null
            ? repository.updateAwardType(id, params.data)
            : repository.createAwardType(params.data);
      case HrConfigEntityType.badge:
        return id != null
            ? repository.updateBadge(id, params.data)
            : repository.createBadge(params.data);
      case HrConfigEntityType.reward:
        return id != null
            ? repository.updateReward(id, params.data)
            : repository.createReward(params.data);
      case HrConfigEntityType.policyRule:
        return id != null
            ? repository.updatePolicyRule(id, params.data)
            : repository.createPolicyRule(params.data);
    }
  }
}

class SaveHrConfigItemParams extends Equatable {
  final HrConfigEntityType entityType;
  final Map<String, dynamic> data;
  final int? id;

  const SaveHrConfigItemParams({
    required this.entityType,
    required this.data,
    this.id,
  });

  @override
  List<Object?> get props => [entityType, data, id];
}
