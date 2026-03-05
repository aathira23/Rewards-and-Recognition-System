import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';

abstract class PointsEvent extends Equatable {
  const PointsEvent();

  @override
  List<Object> get props => [];
}

class GetPointsSummaryRequested extends PointsEvent {}

class GetPointsHistoryRequested extends PointsEvent {
  final int page;
  final int perPage;
  final String? category;
  final String? startDate;
  final String? endDate;
  final String? walletType;

  const GetPointsHistoryRequested({
    this.page = 1,
    this.perPage = kDefaultPageSize,
    this.category,
    this.startDate,
    this.endDate,
    this.walletType,
  });

  @override
  List<Object> get props => [
        page,
        perPage,
        category ?? '',
        startDate ?? '',
        endDate ?? '',
        walletType ?? ''
      ];
}

class GetLeaderboardRequested extends PointsEvent {
  final String period;

  const GetLeaderboardRequested({this.period = 'MONTHLY'});

  @override
  List<Object> get props => [period];
}
