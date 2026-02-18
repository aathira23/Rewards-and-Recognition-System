import 'package:equatable/equatable.dart';

class AnalyticsEntity extends Equatable {
  final int totalRecognitions;
  final int totalPointsDistributed;
  final double engagementRate;
  final int userCount;
  final String scope;
  final List<Map<String, dynamic>> topRecognizers;
  final List<Map<String, dynamic>> topRecognized;
  final List<Map<String, dynamic>> trends;

  const AnalyticsEntity({
    required this.totalRecognitions,
    required this.totalPointsDistributed,
    required this.engagementRate,
    required this.userCount,
    required this.scope,
    required this.topRecognizers,
    required this.topRecognized,
    required this.trends,
  });

  @override
  List<Object?> get props => [
        totalRecognitions,
        totalPointsDistributed,
        engagementRate,
        userCount,
        scope,
      ];
}
