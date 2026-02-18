import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_analytics_usecase.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetAnalyticsUseCase getAnalyticsUseCase;

  AnalyticsBloc({required this.getAnalyticsUseCase})
      : super(const AnalyticsState()) {
    on<GetAnalyticsRequested>(_onGetAnalytics);
  }

  Future<void> _onGetAnalytics(
    GetAnalyticsRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: AnalyticsStatus.loading));
    final result = await getAnalyticsUseCase(GetAnalyticsParams(
      scope: event.scope,
      fromDate: event.fromDate,
      toDate: event.toDate,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        status: AnalyticsStatus.failure,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: AnalyticsStatus.success,
        data: data,
      )),
    );
  }
}
