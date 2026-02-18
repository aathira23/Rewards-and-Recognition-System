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
