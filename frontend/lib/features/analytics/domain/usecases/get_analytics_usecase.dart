import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/analytics_entity.dart';
import '../repositories/analytics_repository.dart';

class GetAnalyticsParams {
  final String? scope;
  final String? fromDate;
  final String? toDate;
  const GetAnalyticsParams({this.scope, this.fromDate, this.toDate});
}

class GetAnalyticsUseCase
    implements UseCase<AnalyticsEntity, GetAnalyticsParams> {
  final AnalyticsRepository repository;
  GetAnalyticsUseCase(this.repository);

  @override
  Future<Either<Failure, AnalyticsEntity>> call(
      GetAnalyticsParams params) async {
    return await repository.getDashboardMetrics(
      scope: params.scope,
      fromDate: params.fromDate,
      toDate: params.toDate,
    );
  }
}
