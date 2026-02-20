import '../../domain/entities/points_rule_entity.dart';

class PointsRuleModel extends PointsRuleEntity {
  const PointsRuleModel({
    super.id,
    required super.name,
    super.description,
    required super.points,
  });

  factory PointsRuleModel.fromJson(Map<String, dynamic> json) {
    return PointsRuleModel(
      id: json['id'],
      name: (json['rule_name'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      points: json['points_value'] ?? json['points'] ?? 0,
    );
  }
}
