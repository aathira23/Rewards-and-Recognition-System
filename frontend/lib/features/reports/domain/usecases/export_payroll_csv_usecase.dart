import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/reports_repository.dart';

class ExportPayrollCsvUseCase implements UseCase<void, ExportPayrollCsvParams> {
  final ReportsRepository repository;

  ExportPayrollCsvUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ExportPayrollCsvParams params) {
    return repository.exportPayrollCsv(params.month);
  }
}

class ExportPayrollCsvParams extends Equatable {
  final String month;

  const ExportPayrollCsvParams({required this.month});

  @override
  List<Object?> get props => [month];
}
