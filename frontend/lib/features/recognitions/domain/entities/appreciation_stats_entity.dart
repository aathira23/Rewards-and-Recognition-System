import 'package:equatable/equatable.dart';
import 'recognition_entity.dart';

class AppreciationStatsEntity extends Equatable {
  final int receivedCount;
  final int sentCount;
  final Map<String, int> badgeCounts;
  final Map<String, String?> badgeIcons;
  final List<RecognitionEntity>? sentRecognitions;
  final List<RecognitionEntity>? receivedRecognitions;

  /// eCard sending limits from the ECARD points policy.
  /// [monthlyLimit] is null when no limit is configured.
  final int? monthlyLimit;
  final int monthlySent;
  final int? cooldownDays;
  final int? consecutiveLimit;
  final int? cooldownHours;

  /// Non-null only when the sender is currently in a cooldown window.
  final DateTime? nextAvailableAt;

  const AppreciationStatsEntity({
    required this.receivedCount,
    required this.sentCount,
    required this.badgeCounts,
    required this.badgeIcons,
    this.sentRecognitions = const [],
    this.receivedRecognitions = const [],
    this.monthlyLimit,
    this.monthlySent = 0,
    this.cooldownDays,
    this.consecutiveLimit,
    this.cooldownHours,
    this.nextAvailableAt,
  });

  @override
  List<Object?> get props => [
        receivedCount,
        sentCount,
        badgeCounts,
        badgeIcons,
        sentRecognitions,
        receivedRecognitions,
        monthlyLimit,
        monthlySent,
        cooldownDays,
        consecutiveLimit,
        cooldownHours,
        nextAvailableAt,
      ];
}
