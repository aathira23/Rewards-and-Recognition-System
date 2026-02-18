import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

class GetAnalyticsRequested extends AnalyticsEvent {
  final String? scope;
  final String? fromDate;
  final String? toDate;
  const GetAnalyticsRequested({this.scope, this.fromDate, this.toDate});
  @override
  List<Object?> get props => [scope, fromDate, toDate];
}
