import 'package:equatable/equatable.dart';

abstract class CelebrationsEvent extends Equatable {
  const CelebrationsEvent();
  @override
  List<Object?> get props => [];
}

class GetUpcomingCelebrationsRequested extends CelebrationsEvent {
  final int days;
  const GetUpcomingCelebrationsRequested({this.days = 30});
  @override
  List<Object?> get props => [days];
}

class GetCelebrationHistoryRequested extends CelebrationsEvent {}

class ProcessTodayCelebrationsRequested extends CelebrationsEvent {}
