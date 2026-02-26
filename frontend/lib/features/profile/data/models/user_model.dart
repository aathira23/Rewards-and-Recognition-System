import '../../domain/entities/user_entity.dart';

/// "Data model for User Profile, mapping backend JSON response to the entity."
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.departmentId,
    super.managerId,
  });

  /// Factory constructor to create a UserModel from JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // The backend users_service.serialize_user returns:
    // { "id": int, "name": str, "email": str, "role": str, "department_id": int/null, "manager_id": int/null ... }
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      departmentId: json['department_id'],
      managerId: json['manager_id'],
    );
  }

  /// Converts the model back to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'department_id': departmentId,
      'manager_id': managerId,
    };
  }
}
