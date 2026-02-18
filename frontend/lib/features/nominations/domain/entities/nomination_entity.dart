import 'package:equatable/equatable.dart';

class NominationEntity extends Equatable {
  final int id;
  final int nomineeId;
  final String nomineeName;
  final int nominatorId;
  final String nominatorName;
  final int awardTypeId;
  final String awardTypeName;
  final String status;
  final int? pointsAwarded;
  final String justification;
  final String createdAt;

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
    required this.justification,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, nomineeId, nominatorId, awardTypeId, status];
}
