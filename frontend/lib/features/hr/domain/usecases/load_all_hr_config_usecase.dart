import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';
import '../repositories/hr_config_repository.dart';

class LoadAllHrConfigUseCase implements UseCase<HrConfigData, NoParams> {
  final HrConfigRepository repository;
  const LoadAllHrConfigUseCase(this.repository);

  @override
  Future<Either<Failure, HrConfigData>> call(NoParams params) {
    return repository.loadAll();
  }
}
