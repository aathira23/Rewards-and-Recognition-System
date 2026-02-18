import '../../domain/entities/point_transaction_entity.dart';

class PointTransactionModel extends PointTransactionEntity {
  const PointTransactionModel({
    required super.id,
    required super.date,
    required super.description,
    required super.type,
    required super.points,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: json['id'],
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      points: json['points'] ?? '0',
    );
  }
}
