import 'package:equatable/equatable.dart';

class AwardTypeEntity extends Equatable {
  final int id;
  final String awardKey;
  final String name;
  final int points;
  final String frequency;
  final String eligibilityRule;
  final String? description;

  const AwardTypeEntity({
    required this.id,
    required this.awardKey,
    required this.name,
    required this.points,
    required this.frequency,
    required this.eligibilityRule,
    this.description,
  });

  @override
  List<Object?> get props =>
      [id, awardKey, name, points, frequency, eligibilityRule];
}
