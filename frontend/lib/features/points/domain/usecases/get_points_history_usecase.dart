import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/point_transaction_entity.dart';
import '../repositories/points_repository.dart';

class GetPointsHistoryParams {
  final int page;

  GetPointsHistoryParams({this.page = 1});
}

class GetPointsHistoryUseCase
    implements UseCase<List<PointTransactionEntity>, GetPointsHistoryParams> {
  final PointsRepository repository;

  GetPointsHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<PointTransactionEntity>>> call(
      GetPointsHistoryParams params) async {
    return await repository.getPointsHistory(page: params.page);
  }
}
