import '../../domain/entities/department_entity.dart';

/// Data model for Department, mapping backend JSON to entity.
class DepartmentModel extends DepartmentEntity {
  const DepartmentModel({required super.id, required super.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
