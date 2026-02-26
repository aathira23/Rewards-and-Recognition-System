import '../../domain/entities/award_type_entity.dart';

class AwardTypeModel extends AwardTypeEntity {
  const AwardTypeModel({
    required super.id,
    required super.awardKey,
    required super.name,
    required super.points,
    required super.frequency,
    required super.eligibilityRule,
    super.description,
  });

  factory AwardTypeModel.fromJson(Map<String, dynamic> json) {
    return AwardTypeModel(
      id: json['id'] ?? 0,
      awardKey: json['award_key'] ?? '',
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
      frequency: json['frequency'] ?? '',
      eligibilityRule: json['eligibility_rule'] ?? '',
      description: json['description'],
    );
  }
}
