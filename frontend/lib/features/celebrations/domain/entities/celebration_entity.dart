import 'package:equatable/equatable.dart';

class CelebrationEntity extends Equatable {
  final int id;
  final int userId;
  final String userName;
  final String celebrationType;
  final String celebrationDate;
  final int pointsAwarded;
  final String createdAt;

  const CelebrationEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.celebrationType,
    required this.celebrationDate,
    required this.pointsAwarded,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, userId, userName, celebrationType, celebrationDate, pointsAwarded];
}
