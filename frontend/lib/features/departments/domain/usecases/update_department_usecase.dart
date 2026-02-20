import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/department_entity.dart';
import '../repositories/department_repository.dart';

class UpdateDepartmentUseCase
    implements UseCase<DepartmentEntity, UpdateDepartmentParams> {
  final DepartmentRepository repository;

  UpdateDepartmentUseCase(this.repository);

  @override
  Future<Either<Failure, DepartmentEntity>> call(
      UpdateDepartmentParams params) {
    return repository.updateDepartment(params.id, params.name);
  }
}

class UpdateDepartmentParams extends Equatable {
  final int id;
  final String name;

  const UpdateDepartmentParams({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
