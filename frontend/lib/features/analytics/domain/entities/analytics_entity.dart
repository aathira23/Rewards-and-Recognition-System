import 'package:equatable/equatable.dart';

class AnalyticsEntity extends Equatable {
  final int totalRecognitions;
  final int totalPointsAwarded;
  final int activeUsers;
  final double budgetUtilization;
  final List<Map<String, dynamic>> topPerformers;
  final List<Map<String, dynamic>> departmentBreakdown;

  const AnalyticsEntity({
    required this.totalRecognitions,
    required this.totalPointsAwarded,
    required this.activeUsers,
    required this.budgetUtilization,
    required this.topPerformers,
    required this.departmentBreakdown,
  });

  @override
  List<Object?> get props => [
        totalRecognitions,
        totalPointsAwarded,
        activeUsers,
        budgetUtilization,
      ];
}
