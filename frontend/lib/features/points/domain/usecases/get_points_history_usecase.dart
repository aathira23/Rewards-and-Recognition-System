import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/point_transaction_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsHistoryParams {
  final int page;
  final String? category;
  final String? startDate;
  final String? endDate;

  GetPointsHistoryParams({
    this.page = 1,
    this.category,
    this.startDate,
    this.endDate,
  });
}

class GetPointsHistoryUseCase
    implements
        UseCase<(int, List<PointTransactionEntity>), GetPointsHistoryParams> {
  final PointsRepository repository;

  GetPointsHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, (int, List<PointTransactionEntity>)>> call(
      GetPointsHistoryParams params) async {
    return await repository.getPointsHistory(
      page: params.page,
      category: params.category,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
