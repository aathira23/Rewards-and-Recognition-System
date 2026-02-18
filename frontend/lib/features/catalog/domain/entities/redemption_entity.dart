class RedemptionEntity {
  final int id;
  final int userId;
  final int rewardId;
  final String rewardName;
  final String rewardCategory;
  final int pointsSpent;
  final String status;
  final DateTime createdAt;

  RedemptionEntity({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.rewardCategory,
    required this.pointsSpent,
    required this.status,
    required this.createdAt,
  });
}
