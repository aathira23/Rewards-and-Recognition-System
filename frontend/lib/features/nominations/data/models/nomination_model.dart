import '../../domain/entities/nomination_entity.dart';

class NominationModel extends NominationEntity {
  const NominationModel({
    required super.id,
    required super.nomineeId,
    required super.nomineeName,
    required super.nominatorId,
    required super.nominatorName,
    required super.awardTypeId,
    required super.awardTypeName,
    required super.status,
    super.pointsAwarded,
    required super.justification,
    required super.createdAt,
  });

  factory NominationModel.fromJson(Map<String, dynamic> json) {
    return NominationModel(
      id: json['id'] ?? 0,
      nomineeId: json['nominee_id'] ?? 0,
      nomineeName:
          json['nominee']?['name'] ?? json['nominee_name'] ?? 'Unknown',
      nominatorId: json['nominator_id'] ?? 0,
      nominatorName:
          json['nominator']?['name'] ?? json['nominator_name'] ?? 'Unknown',
      awardTypeId: json['award_type_id'] ?? 0,
      awardTypeName:
          json['award_type']?['name'] ?? json['award_type_name'] ?? '',
      status: json['status'] ?? 'PENDING',
      pointsAwarded: json['points_awarded'],
      justification: json['justification'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
