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
      id: json['id'],
      userId: json['user_id'],
      rewardId: json['reward_id'],
      rewardName: json['reward_name'] ?? 'Reward',
      rewardCategory: json['reward_category'] ?? 'Category',
      pointsSpent: json['points_spent'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
