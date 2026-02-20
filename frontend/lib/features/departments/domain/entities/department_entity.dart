import 'package:equatable/equatable.dart';

/// Entity representing a department.
class DepartmentEntity extends Equatable {
  final int id;
  final String name;

  const DepartmentEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
