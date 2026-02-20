import 'package:equatable/equatable.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

class LoadBudgetWallet extends BudgetEvent {}

class AllocateBudget extends BudgetEvent {
  final int managerId;
  final int points;

  const AllocateBudget({required this.managerId, required this.points});

  @override
  List<Object?> get props => [managerId, points];
}

class RewardFromBudget extends BudgetEvent {
  final int employeeId;
  final int points;
  final String reason;

  const RewardFromBudget({
    required this.employeeId,
    required this.points,
    required this.reason,
  });

  @override
  List<Object?> get props => [employeeId, points, reason];
}
