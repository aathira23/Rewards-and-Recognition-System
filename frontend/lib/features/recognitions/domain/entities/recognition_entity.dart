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

  /// Source type from the feed: ECARD, AWARD, CELEBRATION
  final String? sourceType;

  /// Persona label (e.g. "Engineering Team")
  final String? actorLabel;

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
    this.sourceType,
    this.actorLabel,
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
        sourceType,
        actorLabel,
      ];
}
