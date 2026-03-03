import 'package:dartz/dartz.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/point_transaction_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsHistoryParams {
  final int page;
  final int perPage;
  final String? category;
  final String? startDate;
  final String? endDate;

  GetPointsHistoryParams({
    this.page = 1,
    this.perPage = kDefaultPageSize,
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
      perPage: params.perPage,
      category: params.category,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
