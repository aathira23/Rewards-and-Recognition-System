import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_points_summary_usecase.dart';
import '../../domain/usecases/get_points_history_usecase.dart';
import 'points_event.dart';
import 'points_state.dart';

class PointsBloc extends Bloc<PointsEvent, PointsState> {
  final GetPointsSummaryUseCase getPointsSummaryUseCase;
  final GetPointsHistoryUseCase getPointsHistoryUseCase;

  PointsBloc({
    required this.getPointsSummaryUseCase,
    required this.getPointsHistoryUseCase,
  }) : super(const PointsState()) {
    on<GetPointsSummaryRequested>(_onGetPointsSummaryRequested);
    on<GetPointsHistoryRequested>(_onGetPointsHistoryRequested);
  }

  Future<void> _onGetPointsSummaryRequested(
    GetPointsSummaryRequested event,
    Emitter<PointsState> emit,
  ) async {
    // Only set loading if internal summary is null? Or just silently update?
    // Let's set distinct loading if we want to show spinner.
    // If we have data, we might want to keep it while refreshing.
    if (state.summary == null) {
      emit(state.copyWith(status: PointsStatus.loading));
    }

    final result = await getPointsSummaryUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: PointsStatus.failure,
        errorMessage: failure.message,
      )),
      (summary) => emit(state.copyWith(
        status: PointsStatus.success,
        summary: summary,
      )),
    );
  }

  Future<void> _onGetPointsHistoryRequested(
    GetPointsHistoryRequested event,
    Emitter<PointsState> emit,
  ) async {
    if (event.page == 1) {
      emit(state.copyWith(
          status: PointsStatus.loading,
          history: [])); // Reset history on refresh
    }

    final result =
        await getPointsHistoryUseCase(GetPointsHistoryParams(page: event.page));
    result.fold(
      (failure) => emit(state.copyWith(
        status: PointsStatus.failure,
        errorMessage: failure.message,
      )),
      (newHistory) {
        final mergedHistory =
            event.page == 1 ? newHistory : List.of(state.history)
              ..addAll(newHistory);

        emit(state.copyWith(
          status: PointsStatus.success,
          history: mergedHistory,
          currentPage: event.page,
          hasReachedMax:
              newHistory.isEmpty, // Simple check. Better if we check < perPage
        ));
      },
    );
  }
}
