import 'package:equatable/equatable.dart';
import 'recognition_entity.dart';

class AppreciationStatsEntity extends Equatable {
  final int receivedCount;
  final int sentCount;
  final Map<String, int> badgeCounts;
  final Map<String, String?> badgeIcons;
  final List<RecognitionEntity>? sentRecognitions;
  final List<RecognitionEntity>? receivedRecognitions;

  const AppreciationStatsEntity({
    required this.receivedCount,
    required this.sentCount,
    required this.badgeCounts,
    required this.badgeIcons,
    this.sentRecognitions = const [],
    this.receivedRecognitions = const [],
  });

  @override
  List<Object?> get props => [
        receivedCount,
        sentCount,
        badgeCounts,
        badgeIcons,
        sentRecognitions,
        receivedRecognitions
      ];
}
