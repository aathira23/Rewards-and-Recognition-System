import 'package:equatable/equatable.dart';

class PointTransactionEntity extends Equatable {
  final int id;
  final int points;
  final String transactionType; // CREDIT, DEBIT
  final String referenceType; // ECARD, AWARD, etc.
  final int referenceId;
  final DateTime createdAt;
  final int? sourceWalletId;
  final int? targetWalletId;
  // TODO: Add extra details like sender name if backend provides it or if we fetch it.

  const PointTransactionEntity({
    required this.id,
    required this.points,
    required this.transactionType,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
    this.sourceWalletId,
    this.targetWalletId,
  });

  @override
  List<Object?> get props => [
        id,
        points,
        transactionType,
        referenceType,
        referenceId,
        createdAt,
        sourceWalletId,
        targetWalletId,
      ];
}
