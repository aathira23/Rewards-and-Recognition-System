import '../../domain/entities/point_transaction_entity.dart';

class PointTransactionModel extends PointTransactionEntity {
  const PointTransactionModel({
    required super.id,
    required super.points,
    required super.transactionType,
    required super.referenceType,
    required super.referenceId,
    required super.createdAt,
    super.sourceWalletId,
    super.targetWalletId,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: json['id'],
      points: json['points'],
      transactionType: json['transaction_type'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      createdAt: DateTime.parse(json['created_at']),
      sourceWalletId: json['source_wallet_id'],
      targetWalletId: json['target_wallet_id'],
    );
  }
}
