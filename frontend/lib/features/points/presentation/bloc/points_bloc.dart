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
    print('PointsBloc: GetPointsSummaryRequested');
    if (state.summary == null) {
      emit(state.copyWith(status: PointsStatus.loading));
    }

    final result = await getPointsSummaryUseCase(NoParams());
    result.fold(
      (failure) {
        print('PointsBloc: Summary Failure: ${failure.message}');
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (summary) {
        print('PointsBloc: Summary Success');
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
    print('PointsBloc: GetPointsHistoryRequested page=${event.page}');
    if (event.page == 1) {
      emit(state.copyWith(status: PointsStatus.loading, history: []));
    }

    final result =
        await getPointsHistoryUseCase(GetPointsHistoryParams(page: event.page));
    result.fold(
      (failure) {
        print('PointsBloc: History Failure: ${failure.message}');
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (newHistory) {
        print('PointsBloc: History Success, count=${newHistory.length}');
        final mergedHistory =
            event.page == 1 ? newHistory : List.of(state.history)
              ..addAll(newHistory);

        emit(state.copyWith(
          status: PointsStatus.success,
          history: mergedHistory,
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
    print('PointsBloc: GetLeaderboardRequested period=${event.period}');
    if (state.leaderboard.isEmpty) {
      emit(state.copyWith(status: PointsStatus.loading));
    }

    final result = await getLeaderboardUseCase(event.period);
    result.fold(
      (failure) {
        print('PointsBloc: Leaderboard Failure: ${failure.message}');
        emit(state.copyWith(
          status: PointsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (leaderboard) {
        print('PointsBloc: Leaderboard Success, count=${leaderboard.length}');
        emit(state.copyWith(
          status: PointsStatus.success,
          leaderboard: leaderboard,
        ));
      },
    );
  }
}
