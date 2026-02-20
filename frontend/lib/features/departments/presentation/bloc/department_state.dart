import 'package:equatable/equatable.dart';
import '../../domain/entities/department_entity.dart';

class DepartmentState extends Equatable {
  final bool isLoading;
  final List<DepartmentEntity> departments;
  final String? error;
  final String? successMessage;

  const DepartmentState({
    this.isLoading = false,
    this.departments = const [],
    this.error,
    this.successMessage,
  });

  DepartmentState copyWith({
    bool? isLoading,
    List<DepartmentEntity>? departments,
    String? error,
    String? successMessage,
  }) {
    return DepartmentState(
      isLoading: isLoading ?? this.isLoading,
      departments: departments ?? this.departments,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, departments, error, successMessage];
}
