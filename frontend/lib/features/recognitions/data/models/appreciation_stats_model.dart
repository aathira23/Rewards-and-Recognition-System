import '../../domain/entities/appreciation_stats_entity.dart';

class AppreciationStatsModel extends AppreciationStatsEntity {
  const AppreciationStatsModel({
    required super.receivedCount,
    required super.sentCount,
    required super.badgeCounts,
  });

  factory AppreciationStatsModel.fromJson(Map<String, dynamic> json) {
    return AppreciationStatsModel(
      receivedCount: json['received_count'] ?? 0,
      sentCount: json['sent_count'] ?? 0,
      badgeCounts: Map<String, int>.from(json['badge_counts'] ?? {}),
    );
  }
}
