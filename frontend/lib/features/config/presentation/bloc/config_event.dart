import 'package:equatable/equatable.dart';

abstract class ConfigEvent extends Equatable {
  const ConfigEvent();

  @override
  List<Object?> get props => [];
}

class LoadConfig extends ConfigEvent {}

class UpdateConfigEntry extends ConfigEvent {
  final String key;
  final String value;
  const UpdateConfigEntry({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
