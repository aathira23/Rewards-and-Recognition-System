import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/department_repository.dart';

class DeleteDepartmentUseCase implements UseCase<void, DeleteDepartmentParams> {
  final DepartmentRepository repository;

  DeleteDepartmentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteDepartmentParams params) {
    return repository.deleteDepartment(params.id);
  }
}

class DeleteDepartmentParams extends Equatable {
  final int id;

  const DeleteDepartmentParams({required this.id});

  @override
  List<Object?> get props => [id];
}
