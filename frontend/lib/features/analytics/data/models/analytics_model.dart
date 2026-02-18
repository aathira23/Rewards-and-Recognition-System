import '../../domain/entities/analytics_entity.dart';

class AnalyticsModel extends AnalyticsEntity {
  const AnalyticsModel({
    required super.totalRecognitions,
    required super.totalPointsAwarded,
    required super.activeUsers,
    required super.budgetUtilization,
    required super.topPerformers,
    required super.departmentBreakdown,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      totalRecognitions: json['total_recognitions'] ?? 0,
      totalPointsAwarded: json['total_points_awarded'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      budgetUtilization: (json['budget_utilization'] ?? 0).toDouble(),
      topPerformers: (json['top_performers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      departmentBreakdown: (json['department_breakdown'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }
}
