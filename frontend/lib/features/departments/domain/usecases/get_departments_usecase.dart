import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/department_entity.dart';
import '../repositories/department_repository.dart';

class GetDepartmentsUseCase
    implements UseCase<List<DepartmentEntity>, NoParams> {
  final DepartmentRepository repository;

  GetDepartmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DepartmentEntity>>> call(NoParams params) {
    return repository.getDepartments();
  }
}
