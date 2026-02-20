import 'package:equatable/equatable.dart';

class HrConfigState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> awardTypes;
  final List<Map<String, dynamic>> badges;
  final List<Map<String, dynamic>> rewards;
  final List<Map<String, dynamic>> policies;
  final List<Map<String, dynamic>> configs;
  final String? error;
  final String? successMessage;

  const HrConfigState({
    this.isLoading = false,
    this.awardTypes = const [],
    this.badges = const [],
    this.rewards = const [],
    this.policies = const [],
    this.configs = const [],
    this.error,
    this.successMessage,
  });

  HrConfigState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? awardTypes,
    List<Map<String, dynamic>>? badges,
    List<Map<String, dynamic>>? rewards,
    List<Map<String, dynamic>>? policies,
    List<Map<String, dynamic>>? configs,
    String? error,
    String? successMessage,
  }) {
    return HrConfigState(
      isLoading: isLoading ?? this.isLoading,
      awardTypes: awardTypes ?? this.awardTypes,
      badges: badges ?? this.badges,
      rewards: rewards ?? this.rewards,
      policies: policies ?? this.policies,
      configs: configs ?? this.configs,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        awardTypes,
        badges,
        rewards,
        policies,
        configs,
        error,
        successMessage,
      ];
}
