import '../../domain/entities/recognition_entity.dart';
import 'badge_model.dart';

class RecognitionModel extends RecognitionEntity {
  const RecognitionModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.badgeId,
    super.message,
    required super.pointsAwarded,
    required super.createdAt,
    super.senderName,
    super.receiverName,
    super.badge,
  });

  factory RecognitionModel.fromJson(Map<String, dynamic> json) {
    return RecognitionModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      badgeId: json['badge_id'],
      message: json['message'],
      pointsAwarded: json['points_awarded'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender']?['name'],
      receiverName: json['receiver']?['name'],
      badge: json['badge'] != null ? BadgeModel.fromJson(json['badge']) : null,
    );
  }
}
