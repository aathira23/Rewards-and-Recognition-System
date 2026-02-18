import 'package:equatable/equatable.dart';

abstract class PointsEvent extends Equatable {
  const PointsEvent();

  @override
  List<Object> get props => [];
}

class GetPointsSummaryRequested extends PointsEvent {}

class GetPointsHistoryRequested extends PointsEvent {
  final int page;

  const GetPointsHistoryRequested({this.page = 1});

  @override
  List<Object> get props => [page];
}

class GetLeaderboardRequested extends PointsEvent {
  final String period;

  const GetLeaderboardRequested({this.period = 'MONTHLY'});

  @override
  List<Object> get props => [period];
}
