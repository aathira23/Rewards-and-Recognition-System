import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_badges_usecase.dart';
import '../../domain/usecases/get_recognition_feed_usecase.dart';
import '../../domain/usecases/send_recognition_usecase.dart';
import '../../domain/usecases/get_appreciation_stats_usecase.dart';
import '../../../profile/domain/usecases/get_users_usecase.dart';
import 'recognitions_event.dart';
import 'recognitions_state.dart';

class RecognitionsBloc extends Bloc<RecognitionsEvent, RecognitionsState> {
  final GetBadgesUseCase getBadgesUseCase;
  final GetRecognitionFeedUseCase getRecognitionFeedUseCase;
  final SendRecognitionUseCase sendRecognitionUseCase;
  final GetAppreciationStatsUseCase getAppreciationStatsUseCase;
  final GetUsersUseCase getUsersUseCase;

  RecognitionsBloc({
    required this.getBadgesUseCase,
    required this.getRecognitionFeedUseCase,
    required this.sendRecognitionUseCase,
    required this.getAppreciationStatsUseCase,
    required this.getUsersUseCase,
  }) : super(const RecognitionsState()) {
    on<GetBadgesRequested>(_onGetBadgesRequested);
    on<GetRecognitionFeedRequested>(_onGetRecognitionFeedRequested);
    on<SendRecognitionRequested>(_onSendRecognitionRequested);
    on<GetAppreciationStatsRequested>(_onGetAppreciationStatsRequested);
    on<GetUsersRequested>(_onGetUsersRequested);
  }

  Future<void> _onGetUsersRequested(
    GetUsersRequested event,
    Emitter<RecognitionsState> emit,
  ) async {
    final result = await getUsersUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (users) => emit(state.copyWith(users: users)),
    );
  }

  Future<void> _onGetBadgesRequested(
    GetBadgesRequested event,
    Emitter<RecognitionsState> emit,
  ) async {
    emit(state.copyWith(status: RecognitionStatus.loading));
    final result = await getBadgesUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: RecognitionStatus.failure,
        errorMessage: failure.message,
      )),
      (badges) => emit(state.copyWith(
        status: RecognitionStatus.success,
        badges: badges,
      )),
    );
  }

  Future<void> _onGetRecognitionFeedRequested(
    GetRecognitionFeedRequested event,
    Emitter<RecognitionsState> emit,
  ) async {
    // Ideally we might want separate statuses for different sections, or a general loading.
    // For now, let's not block the whole UI if just refreshing feed.
    // So we invoke loading status only if it matters globally, or we accept valid partial data.
    // Let's just update the list.
    final result = await getRecognitionFeedUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          errorMessage: failure.message)), // Log error but keep previous state?
      (feed) => emit(state.copyWith(feed: feed)),
    );
  }

  Future<void> _onSendRecognitionRequested(
    SendRecognitionRequested event,
    Emitter<RecognitionsState> emit,
  ) async {
    emit(state.copyWith(status: RecognitionStatus.loading));
    final result = await sendRecognitionUseCase(SendRecognitionParams(
      receiverId: event.receiverId,
      badgeId: event.badgeId,
      message: event.message,
      personaType: event.personaType,
      personaLabel: event.personaLabel,
    ));
    result.fold(
      (failure) => emit(state.copyWith(
        status: RecognitionStatus.failure,
        errorMessage: failure.message,
      )),
      (recognition) {
        emit(state.copyWith(
          status: RecognitionStatus.success,
          lastSentRecognition: recognition,
        ));
        // Refresh feed after sending
        add(GetRecognitionFeedRequested());
        // Refresh stats after sending
        add(GetAppreciationStatsRequested());
      },
    );
  }

  Future<void> _onGetAppreciationStatsRequested(
    GetAppreciationStatsRequested event,
    Emitter<RecognitionsState> emit,
  ) async {
    final result = await getAppreciationStatsUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (stats) => emit(state.copyWith(stats: stats)),
    );
  }
}
