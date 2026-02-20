import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/reports_repository.dart';

class FetchPayrollUseCase
    implements UseCase<List<Map<String, dynamic>>, FetchPayrollParams> {
  final ReportsRepository repository;

  FetchPayrollUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      FetchPayrollParams params) {
    return repository.fetchPayroll(params.month);
  }
}

class FetchPayrollParams extends Equatable {
  final String month;

  const FetchPayrollParams({required this.month});

  @override
  List<Object?> get props => [month];
}
