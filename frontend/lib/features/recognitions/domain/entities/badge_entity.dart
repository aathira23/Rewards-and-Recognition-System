import 'package:equatable/equatable.dart';

class BadgeEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final int? points;

  const BadgeEntity({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.isActive,
    this.points,
  });

  @override
  List<Object?> get props => [id, name, description, iconUrl, isActive, points];
}
