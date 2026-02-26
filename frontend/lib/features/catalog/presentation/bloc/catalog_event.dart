import 'package:equatable/equatable.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class GetCatalogItemsRequested extends CatalogEvent {}

class GetHistoryRequested extends CatalogEvent {}

class GetPointsRulesRequested extends CatalogEvent {}

class RedeemItemRequested extends CatalogEvent {
  final int rewardId;
  const RedeemItemRequested(this.rewardId);

  @override
  List<Object?> get props => [rewardId];
}

class SubmitConversionRequested extends CatalogEvent {
  final int points;
  final String type;

  const SubmitConversionRequested({required this.points, required this.type});

  @override
  List<Object?> get props => [points, type];
}
