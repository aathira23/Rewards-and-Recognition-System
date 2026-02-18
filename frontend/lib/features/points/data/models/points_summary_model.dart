import '../../domain/entities/points_summary_entity.dart';

class PointsSummaryModel extends PointsSummaryEntity {
  const PointsSummaryModel({
    required super.balance,
    required super.totalEarned,
    required super.totalRedeemed,
    required super.pendingCount,
  });

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    return PointsSummaryModel(
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalRedeemed: json['total_redeemed'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
    );
  }
}
