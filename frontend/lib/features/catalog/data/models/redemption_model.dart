import '../../domain/entities/redemption_entity.dart';

class RedemptionModel extends RedemptionEntity {
  RedemptionModel({
    required super.id,
    required super.userId,
    required super.rewardId,
    required super.rewardName,
    required super.rewardCategory,
    required super.pointsSpent,
    required super.status,
    required super.createdAt,
  });

  factory RedemptionModel.fromJson(Map<String, dynamic> json) {
    return RedemptionModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      rewardId: (json['reward_id'] as num).toInt(),
      rewardName: json['reward_name']?.toString() ?? 'Reward',
      rewardCategory: json['reward_category']?.toString() ?? 'Category',
      pointsSpent: (json['points_used'] ?? json['points_spent'] ?? 0) as int,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      // Fallback for cases like +05:30 if it fails
      final cleaned = date.toString().split('.')[0];
      return DateTime.tryParse(cleaned) ?? DateTime.now();
    }
  }
}
