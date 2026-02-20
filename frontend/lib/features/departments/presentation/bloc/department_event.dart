import 'package:equatable/equatable.dart';

abstract class DepartmentEvent extends Equatable {
  const DepartmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDepartments extends DepartmentEvent {}

class CreateDepartment extends DepartmentEvent {
  final String name;
  const CreateDepartment({required this.name});

  @override
  List<Object?> get props => [name];
}

class UpdateDepartment extends DepartmentEvent {
  final int id;
  final String name;
  const UpdateDepartment({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class DeleteDepartment extends DepartmentEvent {
  final int id;
  const DeleteDepartment({required this.id});

  @override
  List<Object?> get props => [id];
}
