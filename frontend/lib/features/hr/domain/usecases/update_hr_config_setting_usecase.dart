import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/hr_config_repository.dart';

class UpdateHrConfigSettingUseCase
    implements UseCase<void, UpdateHrConfigSettingParams> {
  final HrConfigRepository repository;
  const UpdateHrConfigSettingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateHrConfigSettingParams params) {
    return repository.updateConfigSetting(params.key, params.value);
  }
}

class UpdateHrConfigSettingParams extends Equatable {
  final String key;
  final String value;

  const UpdateHrConfigSettingParams({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
