import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/badge_entity.dart';
import '../repositories/recognitions_repository.dart';

class GetBadgesUseCase implements UseCase<List<BadgeEntity>, NoParams> {
  final RecognitionsRepository repository;

  GetBadgesUseCase(this.repository);

  @override
  Future<Either<Failure, List<BadgeEntity>>> call(NoParams params) async {
    return await repository.getBadges();
  }
}
