import 'package:equatable/equatable.dart';

class AnalyticsEntity extends Equatable {
  final int totalRecognitions;
  final int totalPointsDistributed;
  final double engagementRate;
  final int userCount;
  final String scope;
  final String scopeName;
  final List<Map<String, dynamic>> topRecognizers;
  final List<Map<String, dynamic>> topRecognized;
  final List<Map<String, dynamic>> trends;
  /// Per-department (ORG scope) or per-team (DEPARTMENT scope) breakdown.
  /// Each entry: {name, recognition_count, points, user_count, engagement}
  final List<Map<String, dynamic>> breakdown;

  const AnalyticsEntity({
    required this.totalRecognitions,
    required this.totalPointsDistributed,
    required this.engagementRate,
    required this.userCount,
    required this.scope,
    this.scopeName = '',
    required this.topRecognizers,
    required this.topRecognized,
    required this.trends,
    this.breakdown = const [],
  });

  @override
  List<Object?> get props => [
        totalRecognitions,
        totalPointsDistributed,
        engagementRate,
        userCount,
        scope,
        scopeName,
      ];
}
