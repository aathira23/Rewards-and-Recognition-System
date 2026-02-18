import 'package:equatable/equatable.dart';
import '../../domain/entities/points_summary_entity.dart';
import '../../domain/entities/point_transaction_entity.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';

enum PointsStatus { initial, loading, success, failure }

class PointsState extends Equatable {
  final PointsStatus status;
  final PointsSummaryEntity? summary;
  final List<PointTransactionEntity> history;
  final List<LeaderboardEntryEntity> leaderboard;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;

  const PointsState({
    this.status = PointsStatus.initial,
    this.summary,
    this.history = const [],
    this.leaderboard = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 1,
  });

  PointsState copyWith({
    PointsStatus? status,
    PointsSummaryEntity? summary,
    List<PointTransactionEntity>? history,
    List<LeaderboardEntryEntity>? leaderboard,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
  }) {
    return PointsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      history: history ?? this.history,
      leaderboard: leaderboard ?? this.leaderboard,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        history,
        leaderboard,
        hasReachedMax,
        errorMessage,
        currentPage
      ];
}
