import 'package:equatable/equatable.dart';
import '../../domain/entities/budget_wallet_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';

class BudgetState extends Equatable {
  final bool isLoading;
  final BudgetWalletEntity? wallet;
  final List<UserEntity> users;
  final UserEntity? currentUser;
  final String? error;
  final String? successMessage;

  const BudgetState({
    this.isLoading = false,
    this.wallet,
    this.users = const [],
    this.currentUser,
    this.error,
    this.successMessage,
  });

  BudgetState copyWith({
    bool? isLoading,
    BudgetWalletEntity? wallet,
    List<UserEntity>? users,
    UserEntity? currentUser,
    String? error,
    String? successMessage,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      users: users ?? this.users,
      currentUser: currentUser ?? this.currentUser,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, wallet, users, currentUser, error, successMessage];
}
