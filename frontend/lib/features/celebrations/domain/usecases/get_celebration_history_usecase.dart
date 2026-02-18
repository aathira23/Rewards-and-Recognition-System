import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/celebration_entity.dart';
import '../repositories/celebrations_repository.dart';

class GetCelebrationHistoryUseCase
    implements UseCase<List<CelebrationEntity>, NoParams> {
  final CelebrationsRepository repository;
  GetCelebrationHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<CelebrationEntity>>> call(NoParams params) async {
    return await repository.getHistory();
  }
}
