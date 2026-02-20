import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/config_repository.dart';

class UpdateSystemConfigUseCase
    implements UseCase<void, UpdateSystemConfigParams> {
  final ConfigRepository repository;

  UpdateSystemConfigUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSystemConfigParams params) {
    return repository.updateConfig(params.key, params.value);
  }
}

class UpdateSystemConfigParams extends Equatable {
  final String key;
  final String value;

  const UpdateSystemConfigParams({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
