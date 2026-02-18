import 'package:equatable/equatable.dart';

class BadgeEntity extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;

  const BadgeEntity({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, description, iconUrl, isActive];
}
