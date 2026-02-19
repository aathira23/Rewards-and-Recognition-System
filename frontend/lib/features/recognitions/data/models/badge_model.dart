import '../../domain/entities/badge_entity.dart';

class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.name,
    super.description,
    super.iconUrl,
    required super.isActive,
    super.points,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      isActive: json['is_active'] ?? true,
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'is_active': isActive,
      'points': points,
    };
  }
}
