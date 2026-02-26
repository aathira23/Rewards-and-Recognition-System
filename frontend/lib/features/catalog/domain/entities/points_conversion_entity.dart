class PointsConversionEntity {
  final int id;
  final int userId;
  final int pointsConverted;
  final String conversionType;
  final double cashAmount;
  final String status;
  final DateTime createdAt;

  PointsConversionEntity({
    required this.id,
    required this.userId,
    required this.pointsConverted,
    required this.conversionType,
    required this.cashAmount,
    required this.status,
    required this.createdAt,
  });
}
