import 'package:equatable/equatable.dart';
import '../../domain/entities/system_config_entity.dart';
import '../../domain/entities/points_rule_entity.dart';

class ConfigState extends Equatable {
  final bool isLoading;
  final List<SystemConfigEntity> configs;
  final List<PointsRuleEntity> rules;
  final String? error;
  final String? successMessage;

  const ConfigState({
    this.isLoading = false,
    this.configs = const [],
    this.rules = const [],
    this.error,
    this.successMessage,
  });

  ConfigState copyWith({
    bool? isLoading,
    List<SystemConfigEntity>? configs,
    List<PointsRuleEntity>? rules,
    String? error,
    String? successMessage,
  }) {
    return ConfigState(
      isLoading: isLoading ?? this.isLoading,
      configs: configs ?? this.configs,
      rules: rules ?? this.rules,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, configs, rules, error, successMessage];
}
