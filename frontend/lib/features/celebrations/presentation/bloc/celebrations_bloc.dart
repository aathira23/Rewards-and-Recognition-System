import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_upcoming_celebrations_usecase.dart';
import '../../domain/usecases/get_celebration_history_usecase.dart';
import 'celebrations_event.dart';
import 'celebrations_state.dart';

class CelebrationsBloc extends Bloc<CelebrationsEvent, CelebrationsState> {
  final GetUpcomingCelebrationsUseCase getUpcomingUseCase;
  final GetCelebrationHistoryUseCase getHistoryUseCase;

  CelebrationsBloc({
    required this.getUpcomingUseCase,
    required this.getHistoryUseCase,
  }) : super(const CelebrationsState()) {
    on<GetUpcomingCelebrationsRequested>(_onGetUpcoming);
    on<GetCelebrationHistoryRequested>(_onGetHistory);
  }

  Future<void> _onGetUpcoming(
    GetUpcomingCelebrationsRequested event,
    Emitter<CelebrationsState> emit,
  ) async {
    emit(state.copyWith(status: CelebrationsStatus.loading));
    final result = await getUpcomingUseCase(event.days);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CelebrationsStatus.failure,
        errorMessage: failure.message,
      )),
      (upcoming) => emit(state.copyWith(
        status: CelebrationsStatus.success,
        upcoming: upcoming,
      )),
    );
  }

  Future<void> _onGetHistory(
    GetCelebrationHistoryRequested event,
    Emitter<CelebrationsState> emit,
  ) async {
    emit(state.copyWith(status: CelebrationsStatus.loading));
    final result = await getHistoryUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CelebrationsStatus.failure,
        errorMessage: failure.message,
      )),
      (history) => emit(state.copyWith(
        status: CelebrationsStatus.success,
        history: history,
      )),
    );
  }
}
