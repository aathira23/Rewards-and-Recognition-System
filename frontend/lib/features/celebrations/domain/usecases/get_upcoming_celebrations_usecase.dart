import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/celebration_entity.dart';
import '../repositories/celebrations_repository.dart';

class GetUpcomingCelebrationsUseCase
    implements UseCase<List<CelebrationEntity>, int> {
  final CelebrationsRepository repository;
  GetUpcomingCelebrationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CelebrationEntity>>> call(int days) async {
    return await repository.getUpcoming(days: days);
  }
}
