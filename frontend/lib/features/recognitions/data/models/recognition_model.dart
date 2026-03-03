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
    super.sourceType,
  });

  factory RecognitionModel.fromJson(Map<String, dynamic> json) {
    return RecognitionModel(
      id: json['id'],
      // Backend feed uses 'actor_id'; eCard detail uses 'sender_id'
      senderId: json['actor_id'] ?? json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      // Feed uses 'source_id' as the related record id; badge_id may be absent
      badgeId: json['badge_id'] ?? json['source_id'] ?? 0,
      message: json['message'],
      pointsAwarded: json['points_awarded'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      // Backend feed uses 'actor' object; eCard detail uses 'sender'
      senderName: json['actor']?['name'] ?? json['sender']?['name'],
      receiverName: json['receiver']?['name'],
      badge: json['badge'] != null ? BadgeModel.fromJson(json['badge']) : null,
      sourceType: json['source_type'],
    );
  }
}
