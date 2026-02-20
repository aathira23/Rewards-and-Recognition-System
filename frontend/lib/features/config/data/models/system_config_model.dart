import '../../domain/entities/system_config_entity.dart';

class SystemConfigModel extends SystemConfigEntity {
  const SystemConfigModel({
    required super.key,
    required super.value,
    super.description,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}
