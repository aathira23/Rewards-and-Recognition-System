import '../../domain/entities/celebration_entity.dart';

class CelebrationModel extends CelebrationEntity {
  const CelebrationModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.celebrationType,
    required super.celebrationDate,
    required super.pointsAwarded,
    required super.createdAt,
  });

  factory CelebrationModel.fromJson(Map<String, dynamic> json) {
    return CelebrationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? json['user']?['name'] ?? 'Unknown',
      celebrationType: json['celebration_type'] ?? '',
      celebrationDate: json['celebration_date'] ?? '',
      pointsAwarded: json['points_awarded'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
