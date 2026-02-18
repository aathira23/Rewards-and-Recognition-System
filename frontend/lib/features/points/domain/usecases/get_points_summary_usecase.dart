import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/points_summary_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsSummaryUseCase
    implements UseCase<PointsSummaryEntity, NoParams> {
  final PointsRepository repository;

  GetPointsSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, PointsSummaryEntity>> call(NoParams params) async {
    return await repository.getPointsSummary();
  }
}
