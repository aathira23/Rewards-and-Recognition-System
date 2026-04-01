import 'package:equatable/equatable.dart';

/// Core entity representing a user across all features.
class UserEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? departmentId;
  final String? departmentName;
  final int? managerId;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.managerId,
  });

  @override
  List<Object?> get props =>
      [id, name, email, role, departmentId, departmentName, managerId];
}
