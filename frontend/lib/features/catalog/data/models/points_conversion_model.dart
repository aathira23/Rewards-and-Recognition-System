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
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      pointsConverted: (json['points_converted'] ?? 0) as int,
      conversionType: json['conversion_type']?.toString() ?? 'PAYROLL',
      cashAmount: double.tryParse(json['cash_amount'].toString()) ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: _parseDateTime(json['requested_at'] ?? json['created_at']),
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      final cleaned = date.toString().split('.')[0];
      return DateTime.tryParse(cleaned) ?? DateTime.now();
    }
  }
}
