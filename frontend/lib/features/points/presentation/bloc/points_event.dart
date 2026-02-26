import 'package:equatable/equatable.dart';

abstract class PointsEvent extends Equatable {
  const PointsEvent();

  @override
  List<Object> get props => [];
}

class GetPointsSummaryRequested extends PointsEvent {}

class GetPointsHistoryRequested extends PointsEvent {
  final int page;
  final String? category;
  final String? startDate;
  final String? endDate;

  const GetPointsHistoryRequested({
    this.page = 1,
    this.category,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object> get props =>
      [page, category ?? '', startDate ?? '', endDate ?? ''];
}

class GetLeaderboardRequested extends PointsEvent {
  final String period;

  const GetLeaderboardRequested({this.period = 'MONTHLY'});

  @override
  List<Object> get props => [period];
}
