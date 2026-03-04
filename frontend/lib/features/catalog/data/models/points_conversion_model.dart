import '../../domain/entities/points_conversion_entity.dart';

class PointsConversionModel extends PointsConversionEntity {
  PointsConversionModel({
    required super.id,
    required super.userId,
    required super.pointsConverted,
    required super.conversionType,
    required super.cashAmount,
    required super.status,
    required super.createdAt,
  });

  factory PointsConversionModel.fromJson(Map<String, dynamic> json) {
    return PointsConversionModel(
      id: json['id'],
      userId: json['user_id'],
      pointsConverted: json['points_converted'],
      conversionType: json['conversion_type'],
      cashAmount: (json['cash_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
