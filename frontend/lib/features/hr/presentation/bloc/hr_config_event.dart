import 'package:equatable/equatable.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';

abstract class HrConfigEvent extends Equatable {
  const HrConfigEvent();
  @override
  List<Object?> get props => [];
}

class LoadAllHrConfig extends HrConfigEvent {}

class SaveItem extends HrConfigEvent {
  final HrConfigEntityType entityType;
  final Map<String, dynamic> data;
  final int? id;

  const SaveItem({required this.entityType, required this.data, this.id});

  @override
  List<Object?> get props => [entityType, data, id];
}

class ToggleItem extends HrConfigEvent {
  final HrConfigEntityType entityType;
  final int id;
  final bool currentlyActive;

  const ToggleItem({
    required this.entityType,
    required this.id,
    required this.currentlyActive,
  });

  @override
  List<Object?> get props => [entityType, id, currentlyActive];
}

class UpdateConfigSetting extends HrConfigEvent {
  final String key;
  final String value;

  const UpdateConfigSetting({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
