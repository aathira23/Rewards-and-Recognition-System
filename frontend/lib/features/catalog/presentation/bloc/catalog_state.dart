import 'package:equatable/equatable.dart';
import '../../domain/entities/reward_entity.dart';
import '../../domain/entities/redemption_entity.dart';
import '../../domain/entities/points_conversion_entity.dart';

enum CatalogStatus { initial, loading, success, failure }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<RewardEntity> items;
  final List<RedemptionEntity> redemptions;
  final List<PointsConversionEntity> conversions;
  final List<Map<String, dynamic>> pointsRules;
  final String? errorMessage;
  final bool? redemptionSuccess;
  final bool? conversionSuccess;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.items = const [],
    this.redemptions = const [],
    this.conversions = const [],
    this.pointsRules = const [],
    this.errorMessage,
    this.redemptionSuccess,
    this.conversionSuccess,
  });

  CatalogState copyWith({
    CatalogStatus? status,
    List<RewardEntity>? items,
    List<RedemptionEntity>? redemptions,
    List<PointsConversionEntity>? conversions,
    List<Map<String, dynamic>>? pointsRules,
    String? errorMessage,
    bool? redemptionSuccess,
    bool? conversionSuccess,
  }) {
    return CatalogState(
      status: status ?? this.status,
      items: items ?? this.items,
      redemptions: redemptions ?? this.redemptions,
      conversions: conversions ?? this.conversions,
      pointsRules: pointsRules ?? this.pointsRules,
      errorMessage: errorMessage,
      redemptionSuccess: redemptionSuccess,
      conversionSuccess: conversionSuccess,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        redemptions,
        conversions,
        pointsRules,
        errorMessage,
        redemptionSuccess,
        conversionSuccess
      ];
}
