import '../../domain/entities/budget_wallet_entity.dart';

class BudgetWalletModel extends BudgetWalletEntity {
  const BudgetWalletModel({required super.balance, super.raw});

  factory BudgetWalletModel.fromJson(Map<String, dynamic> json) {
    return BudgetWalletModel(
      balance: json['balance'] ?? 0,
      raw: json,
    );
  }
}
