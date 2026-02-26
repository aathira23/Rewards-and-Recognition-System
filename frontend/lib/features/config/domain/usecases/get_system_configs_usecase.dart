import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/system_config_entity.dart';
import '../repositories/config_repository.dart';

class GetSystemConfigsUseCase
    implements UseCase<List<SystemConfigEntity>, NoParams> {
  final ConfigRepository repository;

  GetSystemConfigsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SystemConfigEntity>>> call(NoParams params) {
    return repository.getConfigs();
  }
}
