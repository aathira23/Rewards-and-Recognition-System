import 'package:equatable/equatable.dart';
import 'badge_entity.dart';

class RecognitionEntity extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final int badgeId;
  final String? message;
  final int pointsAwarded;
  final DateTime createdAt;
  final String? senderName;
  final String? receiverName;
  final BadgeEntity? badge;

  const RecognitionEntity({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.badgeId,
    this.message,
    required this.pointsAwarded,
    required this.createdAt,
    this.senderName,
    this.receiverName,
    this.badge,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        badgeId,
        message,
        pointsAwarded,
        createdAt,
        senderName,
        receiverName,
        badge,
      ];
}
