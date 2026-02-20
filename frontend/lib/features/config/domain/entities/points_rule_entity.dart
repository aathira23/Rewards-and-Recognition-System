import 'package:equatable/equatable.dart';

/// Entity representing a points rule.
class PointsRuleEntity extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final int points;

  const PointsRuleEntity({
    this.id,
    required this.name,
    this.description,
    required this.points,
  });

  @override
  List<Object?> get props => [id, name, description, points];
}
