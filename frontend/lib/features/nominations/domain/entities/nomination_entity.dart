import 'package:equatable/equatable.dart';

class NominationEntity extends Equatable {
  final int id;
  final int nomineeId;
  final String nomineeName;
  final int nominatorId;
  final String nominatorName;
  final int awardTypeId;
  final String awardTypeName;
  final String? nextRequiredLevel;
  final String status;
  final int? pointsAwarded;
  final String citation;
  final String createdAt;
  final String? reviewerComment;
  final String? reviewerName;
  final String? reviewerLevel;

  const NominationEntity({
    required this.id,
    required this.nomineeId,
    required this.nomineeName,
    required this.nominatorId,
    required this.nominatorName,
    required this.awardTypeId,
    required this.awardTypeName,
    required this.status,
    this.pointsAwarded,
    required this.citation,
    required this.createdAt,
    this.nextRequiredLevel,
    this.reviewerComment,
    this.reviewerName,
    this.reviewerLevel,
  });

  @override
  List<Object?> get props => [
        id,
        nomineeId,
        nomineeName,
        nominatorId,
        nominatorName,
        awardTypeId,
        awardTypeName,
        status,
        pointsAwarded,
        citation,
        createdAt,
        nextRequiredLevel,
        reviewerComment,
        reviewerName,
        reviewerLevel,
      ];
}
