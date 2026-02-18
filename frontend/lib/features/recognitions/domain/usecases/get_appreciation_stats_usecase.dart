import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/appreciation_stats_entity.dart';
import '../repositories/recognitions_repository.dart';

class GetAppreciationStatsUseCase
    implements UseCase<AppreciationStatsEntity, NoParams> {
  final RecognitionsRepository repository;

  GetAppreciationStatsUseCase(this.repository);

  @override
  Future<Either<Failure, AppreciationStatsEntity>> call(NoParams params) async {
    return await repository.getAppreciationStats();
  }
}
