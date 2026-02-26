import 'package:equatable/equatable.dart';

/// Entity representing a system configuration entry.
class SystemConfigEntity extends Equatable {
  final String key;
  final String value;
  final String? description;

  const SystemConfigEntity({
    required this.key,
    required this.value,
    this.description,
  });

  @override
  List<Object?> get props => [key, value, description];
}
