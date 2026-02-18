import '../../domain/entities/analytics_entity.dart';

class AnalyticsModel extends AnalyticsEntity {
  const AnalyticsModel({
    required super.totalRecognitions,
    required super.totalPointsDistributed,
    required super.engagementRate,
    required super.userCount,
    required super.scope,
    required super.topRecognizers,
    required super.topRecognized,
    required super.trends,
  });

  /// Backend response shape:
  /// {
  ///   "summary": { "total_recognitions": N, "total_points_distributed": N, "engagement_rate": F },
  ///   "trends": [ {"date": "YYYY-MM-DD", "count": N}, ... ],
  ///   "top_recognizers": [ {"name": "...", "count": N}, ... ],
  ///   "top_recognized":  [ {"name": "...", "count": N}, ... ],
  ///   "scope": "ORG" | "DEPARTMENT" | "TEAM",
  ///   "user_count": N
  /// }
  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map<String, dynamic>?) ?? {};
    return AnalyticsModel(
      totalRecognitions: summary['total_recognitions'] ?? 0,
      totalPointsDistributed: summary['total_points_distributed'] ?? 0,
      engagementRate: (summary['engagement_rate'] ?? 0).toDouble(),
      userCount: json['user_count'] ?? 0,
      scope: json['scope']?.toString() ?? '',
      topRecognizers: (json['top_recognizers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      topRecognized: (json['top_recognized'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      trends: (json['trends'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}
