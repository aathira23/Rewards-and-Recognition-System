import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_budget_wallet_usecase.dart';
import '../../domain/usecases/allocate_budget_usecase.dart';
import '../../domain/usecases/reward_employee_usecase.dart';
import '../../../profile/domain/usecases/get_me_usecase.dart';
import '../../../profile/domain/usecases/get_users_usecase.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final GetBudgetWalletUseCase getBudgetWalletUseCase;
  final AllocateBudgetUseCase allocateBudgetUseCase;
  final RewardEmployeeUseCase rewardEmployeeUseCase;
  final GetUsersUseCase getUsersUseCase;
  final GetMeUseCase getMeUseCase;

  BudgetBloc({
    required this.getBudgetWalletUseCase,
    required this.allocateBudgetUseCase,
    required this.rewardEmployeeUseCase,
    required this.getUsersUseCase,
    required this.getMeUseCase,
  }) : super(const BudgetState()) {
    on<LoadBudgetWallet>(_onLoad);
    on<LoadBudgetUsers>(_onLoadUsers);
    on<LoadCurrentUser>(_onLoadMe);
    on<AllocateBudget>(_onAllocate);
    on<RewardFromBudget>(_onReward);
    on<ClearBudgetMessages>(_onClearMessages);
  }

  void _onClearMessages(ClearBudgetMessages event, Emitter<BudgetState> emit) {
    emit(state.copyWith(successMessage: null, error: null));
  }

  Future<void> _onLoadMe(
      LoadCurrentUser event, Emitter<BudgetState> emit) async {
    final result = await getMeUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (user) => emit(state.copyWith(currentUser: user)),
    );
  }

  Future<void> _onLoadUsers(
      LoadBudgetUsers event, Emitter<BudgetState> emit) async {
    final result = await getUsersUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (users) => emit(state.copyWith(users: users)),
    );
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
