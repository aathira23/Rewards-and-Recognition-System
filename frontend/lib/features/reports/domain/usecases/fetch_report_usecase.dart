import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/reports_repository.dart';

class FetchReportUseCase
    extends UseCase<List<Map<String, dynamic>>, FetchReportParams> {
  final ReportsRepository repository;

  FetchReportUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      FetchReportParams params) {
    return repository.fetchReport(params.queryParams);
  }
}

class FetchReportParams extends Equatable {
  final Map<String, dynamic> queryParams;

  const FetchReportParams({required this.queryParams});

  @override
  List<Object?> get props => [queryParams];
}
