import 'package:equatable/equatable.dart';

class AppreciationStatsEntity extends Equatable {
  final int receivedCount;
  final int sentCount;
  final Map<String, int> badgeCounts;

  const AppreciationStatsEntity({
    required this.receivedCount,
    required this.sentCount,
    required this.badgeCounts,
  });

  @override
  List<Object?> get props => [receivedCount, sentCount, badgeCounts];
}
