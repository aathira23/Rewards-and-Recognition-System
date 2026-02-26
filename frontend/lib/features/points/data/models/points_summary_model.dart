import '../../domain/entities/points_summary_entity.dart';

class PointsSummaryModel extends PointsSummaryEntity {
  const PointsSummaryModel({
    required super.balance,
    required super.totalEarned,
    required super.totalRedeemed,
    super.totalConverted,
    required super.pendingCount,
    required super.expiringToday,
    required super.expiringThisMonth,
  });

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    return PointsSummaryModel(
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalRedeemed: json['total_redeemed'] ?? 0,
      totalConverted: json['total_converted'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      expiringToday: json['expiring_today'] ?? 0,
      expiringThisMonth: json['expiring_this_month'] ?? 0,
    );
  }
}
