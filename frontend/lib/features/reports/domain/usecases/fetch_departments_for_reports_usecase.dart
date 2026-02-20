import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/reports_repository.dart';

class FetchDepartmentsForReportsUseCase
    extends UseCase<List<Map<String, dynamic>>, NoParams> {
  final ReportsRepository repository;

  FetchDepartmentsForReportsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(NoParams params) {
    return repository.fetchDepartments();
  }
}
