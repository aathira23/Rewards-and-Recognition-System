import '../../domain/entities/appreciation_stats_entity.dart';
import 'recognition_model.dart';

class AppreciationStatsModel extends AppreciationStatsEntity {
  const AppreciationStatsModel({
    required super.receivedCount,
    required super.sentCount,
    required super.badgeCounts,
    required super.badgeIcons,
    super.sentRecognitions,
  });

  factory AppreciationStatsModel.fromJson(Map<String, dynamic> json) {
    // Backend returns total_received / total_sent and a 'received' list of
    // ecard objects. We derive badge_counts by tallying badge names from
    // the received list.
    final int receivedCount =
        json['total_received'] ?? json['received_count'] ?? 0;
    final int sentCount = json['total_sent'] ?? json['sent_count'] ?? 0;

    final Map<String, int> badgeCounts = {};
    final Map<String, String?> badgeIcons = {};
    final List receivedList = json['received'] as List? ?? [];
    for (final ecard in receivedList) {
      final badge = ecard['badge'];
      final String badgeName = (badge != null && badge['name'] != null)
          ? badge['name'] as String
          : 'Badge #${ecard['badge_id']}';
      badgeCounts[badgeName] = (badgeCounts[badgeName] ?? 0) + 1;
      
      // Store icon URL if present
      if (badge != null && badge['icon_url'] != null) {
        badgeIcons[badgeName] = badge['icon_url'] as String;
      }
    }

    final List sentList = json['sent'] as List? ?? [];
    final sentRecognitions =
        sentList.map((e) => RecognitionModel.fromJson(e)).toList();

    return AppreciationStatsModel(
      receivedCount: receivedCount,
      sentCount: sentCount,
      badgeCounts: badgeCounts,
      badgeIcons: badgeIcons,
      sentRecognitions: sentRecognitions,
    );
  }

  /// Returns a zero-value stats object used as a safe fallback when the
  /// API call fails (e.g. network error on web).
  factory AppreciationStatsModel.empty() {
    return const AppreciationStatsModel(
      receivedCount: 0,
      sentCount: 0,
      badgeCounts: {},
      badgeIcons: {},
      sentRecognitions: [],
    );
  }
}
