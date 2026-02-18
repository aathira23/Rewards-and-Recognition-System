import 'package:equatable/equatable.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/recognition_entity.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';

enum RecognitionStatus { initial, loading, success, failure }

class RecognitionsState extends Equatable {
  final RecognitionStatus status;
  final List<BadgeEntity> badges;
  final List<RecognitionEntity> feed;
  final List<UserEntity> users;
  final AppreciationStatsEntity?
      stats; // Nullable as it might load later or separately
  final String? errorMessage;
  final RecognitionEntity? lastSentRecognition; // To track send success

  const RecognitionsState({
    this.status = RecognitionStatus.initial,
    this.badges = const [],
    this.feed = const [],
    this.users = const [],
    this.stats,
    this.errorMessage,
    this.lastSentRecognition,
  });

  RecognitionsState copyWith({
    RecognitionStatus? status,
    List<BadgeEntity>? badges,
    List<RecognitionEntity>? feed,
    List<UserEntity>? users,
    AppreciationStatsEntity? stats,
    String? errorMessage,
    RecognitionEntity? lastSentRecognition,
  }) {
    return RecognitionsState(
      status: status ?? this.status,
      badges: badges ?? this.badges,
      feed: feed ?? this.feed,
      stats: stats ?? this.stats,
      errorMessage:
          errorMessage, // Reset error on new state unless explicitly provided? No, keep logic simple.
      lastSentRecognition: lastSentRecognition ?? this.lastSentRecognition,
    );
  }

  @override
  List<Object?> get props =>
      [status, badges, feed, stats, errorMessage, lastSentRecognition];
}
