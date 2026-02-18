import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class GetNotificationsRequested extends NotificationsEvent {}

class GetUnreadCountRequested extends NotificationsEvent {}

class MarkAllAsReadRequested extends NotificationsEvent {}

class MarkOneAsReadRequested extends NotificationsEvent {
  final int notificationId;
  const MarkOneAsReadRequested(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}
