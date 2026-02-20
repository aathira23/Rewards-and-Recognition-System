import 'package:equatable/equatable.dart';

/// Entity representing a manager's budget wallet.
class BudgetWalletEntity extends Equatable {
  final int balance;
  final Map<String, dynamic> raw;

  const BudgetWalletEntity({required this.balance, this.raw = const {}});

  @override
  List<Object?> get props => [balance];
}
