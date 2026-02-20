import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_wallet_entity.dart';

class BudgetState extends Equatable {
  final bool isLoading;
  final BudgetWalletEntity? wallet;
  final String? error;
  final String? successMessage;

  const BudgetState({
    this.isLoading = false,
    this.wallet,
    this.error,
    this.successMessage,
  });

  BudgetState copyWith({
    bool? isLoading,
    BudgetWalletEntity? wallet,
    String? error,
    String? successMessage,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, wallet, error, successMessage];
}
