import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_budget_wallet_usecase.dart';
import '../../domain/usecases/allocate_budget_usecase.dart';
import '../../domain/usecases/reward_employee_usecase.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgetWalletUseCase getBudgetWalletUseCase;
  final AllocateBudgetUseCase allocateBudgetUseCase;
  final RewardEmployeeUseCase rewardEmployeeUseCase;

  BudgetBloc({
    required this.getBudgetWalletUseCase,
    required this.allocateBudgetUseCase,
    required this.rewardEmployeeUseCase,
  }) : super(const BudgetState()) {
    on<LoadBudgetWallet>(_onLoad);
    on<AllocateBudget>(_onAllocate);
    on<RewardFromBudget>(_onReward);
  }

  Future<void> _onLoad(
      LoadBudgetWallet event, Emitter<BudgetState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await getBudgetWalletUseCase(NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (wallet) => emit(state.copyWith(isLoading: false, wallet: wallet)),
    );
  }

  Future<void> _onAllocate(
      AllocateBudget event, Emitter<BudgetState> emit) async {
    emit(state.copyWith(error: null));
    final result = await allocateBudgetUseCase(
        AllocateBudgetParams(managerId: event.managerId, points: event.points));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: 'Budget allocated successfully'));
        add(LoadBudgetWallet());
      },
    );
  }

  Future<void> _onReward(
      RewardFromBudget event, Emitter<BudgetState> emit) async {
    emit(state.copyWith(error: null));
    final result = await rewardEmployeeUseCase(RewardEmployeeParams(
      employeeId: event.employeeId,
      points: event.points,
      reason: event.reason,
    ));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: 'Employee rewarded successfully'));
        add(LoadBudgetWallet());
      },
    );
  }
}
