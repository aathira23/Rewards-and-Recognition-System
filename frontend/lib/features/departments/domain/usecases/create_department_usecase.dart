import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/department_entity.dart';
import '../repositories/department_repository.dart';

class CreateDepartmentUseCase
    implements UseCase<DepartmentEntity, CreateDepartmentParams> {
  final DepartmentRepository repository;

  CreateDepartmentUseCase(this.repository);

  @override
  Future<Either<Failure, DepartmentEntity>> call(
      CreateDepartmentParams params) {
    return repository.createDepartment(params.name);
  }
}

class CreateDepartmentParams extends Equatable {
  final String name;

  const CreateDepartmentParams({required this.name});

  @override
  List<Object?> get props => [name];
}
