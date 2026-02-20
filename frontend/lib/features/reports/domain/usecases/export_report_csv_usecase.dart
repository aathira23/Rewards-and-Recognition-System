import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/reports_repository.dart';

class ExportReportCsvUseCase extends UseCase<void, ExportReportCsvParams> {
  final ReportsRepository repository;

  ExportReportCsvUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ExportReportCsvParams params) {
    return repository.exportReportCsv(params.queryParams);
  }
}

class ExportReportCsvParams extends Equatable {
  final Map<String, dynamic> queryParams;

  const ExportReportCsvParams({required this.queryParams});

  @override
  List<Object?> get props => [queryParams];
}
