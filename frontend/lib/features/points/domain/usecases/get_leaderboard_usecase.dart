import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/leaderboard_entry_entity.dart';
import '../repositories/points_repository.dart';

class GetLeaderboardUseCase
    implements UseCase<List<LeaderboardEntryEntity>, String> {
  final PointsRepository repository;

  GetLeaderboardUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaderboardEntryEntity>>> call(
      String period) async {
    return await repository.getLeaderboard(period: period);
  }
}
