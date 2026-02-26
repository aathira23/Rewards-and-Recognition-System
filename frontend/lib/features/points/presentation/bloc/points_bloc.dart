import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_points_summary_usecase.dart';
import '../../domain/usecases/get_points_history_usecase.dart';
import '../../domain/usecases/get_leaderboard_usecase.dart';
import 'points_event.dart';
import 'points_state.dart';

class PointsBloc extends Bloc<PointsEvent, PointsState> {
  final GetPointsSummaryUseCase getPointsSummaryUseCase;
  final GetPointsHistoryUseCase getPointsHistoryUseCase;
  final GetLeaderboardUseCase getLeaderboardUseCase;

  PointsBloc({
    required this.getPointsSummaryUseCase,
    required this.getPointsHistoryUseCase,
    required this.getLeaderboardUseCase,
  }) : super(const PointsState()) {
    on<GetPointsSummaryRequested>(_onGetPointsSummaryRequested);
    on<GetPointsHistoryRequested>(_onGetPointsHistoryRequested);
    on<GetLeaderboardRequested>(_onGetLeaderboardRequested);
  }

  Future<void> _onGetPointsSummaryRequested(
    GetPointsSummaryRequested event,
    Emitter<PointsState> emit,
  ) async {
    if (state.summary == null) {
      emit(state.copyWith(status: PointsStatus.loading));
    }

    final result = await getPointsSummaryUseCase(NoParams());
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (summary) {
        emit(state.copyWith(
          status: PointsStatus.success,
          summary: summary,
        ));
      },
    );
  }

  Future<void> _onGetPointsHistoryRequested(
    GetPointsHistoryRequested event,
    Emitter<PointsState> emit,
  ) async {
    if (event.page == 1) {
      emit(state.copyWith(status: PointsStatus.loading, history: []));
    }

    final result = await getPointsHistoryUseCase(GetPointsHistoryParams(
      page: event.page,
      category: event.category,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (bundle) {
        final (total, newHistory) = bundle;
        final mergedHistory = event.page == 1
            ? newHistory
            : (List.of(state.history)..addAll(newHistory));

        emit(state.copyWith(
          status: PointsStatus.success,
          history: mergedHistory,
          historyTotal: total,
          currentPage: event.page,
          hasReachedMax: newHistory.isEmpty,
        ));
      },
    );
  }

  Future<void> _onGetLeaderboardRequested(
    GetLeaderboardRequested event,
    Emitter<PointsState> emit,
  ) async {
    // Always reload so period switches are always reflected
    emit(state.copyWith(status: PointsStatus.loading));

    final result = await getLeaderboardUseCase(event.period);
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (leaderboard) {
        emit(state.copyWith(
          status: PointsStatus.success,
          leaderboard: leaderboard,
        ));
      },
    );
  }
}
