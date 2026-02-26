import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkAsReadUseCase markAsReadUseCase;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markAsReadUseCase,
  }) : super(const NotificationsState()) {
    on<GetNotificationsRequested>(_onGetNotifications);
    on<GetUnreadCountRequested>(_onGetUnreadCount);
    on<MarkAllAsReadRequested>(_onMarkAllAsRead);
    on<MarkOneAsReadRequested>(_onMarkOneAsRead);
  }

  Future<void> _onGetNotifications(
    GetNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    final result = await getNotificationsUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: failure.message,
      )),
      (notifications) => emit(state.copyWith(
        status: NotificationsStatus.success,
        notifications: notifications,
      )),
    );
  }

  Future<void> _onGetUnreadCount(
    GetUnreadCountRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await getUnreadCountUseCase(NoParams());
    result.fold(
      (_) {},
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await markAsReadUseCase(null);
    add(GetNotificationsRequested());
    add(GetUnreadCountRequested());
  }

  Future<void> _onMarkOneAsRead(
    MarkOneAsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await markAsReadUseCase(event.notificationId);
    add(GetNotificationsRequested());
    add(GetUnreadCountRequested());
  }
}
