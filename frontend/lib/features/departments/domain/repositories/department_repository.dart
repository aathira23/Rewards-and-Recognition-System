import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/department_entity.dart';

abstract class DepartmentRepository {
  Future<Either<Failure, List<DepartmentEntity>>> getDepartments();
  Future<Either<Failure, DepartmentEntity>> createDepartment(String name);
  Future<Either<Failure, DepartmentEntity>> updateDepartment(
      int id, String name);
  Future<Either<Failure, void>> deleteDepartment(int id);
}
