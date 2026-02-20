import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/hr_approvals_repository.dart';
import 'hr_approvals_event.dart';
import 'hr_approvals_state.dart';

class HrApprovalsBloc extends Bloc<HrApprovalsEvent, HrApprovalsState> {
  final HrApprovalsRepository repository;

  HrApprovalsBloc({required this.repository})
      : super(const HrApprovalsState()) {
    on<LoadNominations>(_onLoadNominations);
    on<ActionNomination>(_onActionNomination);
    on<LoadConversions>(_onLoadConversions);
    on<ActionConversion>(_onActionConversion);
    on<LoadManagers>(_onLoadManagers);
    on<AllocateBudgetToManager>(_onAllocate);
    on<BulkAllocateBudgets>(_onBulkAllocate);
  }

  Future<void> _onLoadNominations(
      LoadNominations event, Emitter<HrApprovalsState> emit) async {
    emit(state.copyWith(nomLoading: true));
    final result = await repository.fetchNominations();
    result.fold(
      (f) => emit(state.copyWith(nomLoading: false, error: f.message)),
      (data) => emit(state.copyWith(nomLoading: false, nominations: data)),
    );
  }

  Future<void> _onActionNomination(
      ActionNomination event, Emitter<HrApprovalsState> emit) async {
    final action = event.isApprove ? 'APPROVE' : 'REJECT';
    final result =
        await repository.actionNomination(event.id, action, event.comments);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        final label = event.isApprove ? 'approved' : 'rejected';
        emit(state.copyWith(successMessage: 'Nomination $label'));
        add(LoadNominations());
      },
    );
  }

  Future<void> _onLoadConversions(
      LoadConversions event, Emitter<HrApprovalsState> emit) async {
    emit(state.copyWith(convLoading: true));
    final result = await repository.fetchConversions();
    result.fold(
      (f) => emit(state.copyWith(convLoading: false, error: f.message)),
      (data) => emit(state.copyWith(convLoading: false, conversions: data)),
    );
  }

  Future<void> _onActionConversion(
      ActionConversion event, Emitter<HrApprovalsState> emit) async {
    final result = await repository.actionConversion(event.id, event.action);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        final label = event.action.toLowerCase();
        emit(state.copyWith(successMessage: 'Conversion ${label}d'));
        add(LoadConversions());
      },
    );
  }

  Future<void> _onLoadManagers(
      LoadManagers event, Emitter<HrApprovalsState> emit) async {
    emit(state.copyWith(mgLoading: true));
    final result = await repository.fetchManagers();
    result.fold(
      (f) => emit(state.copyWith(mgLoading: false, error: f.message)),
      (data) => emit(state.copyWith(mgLoading: false, managers: data)),
    );
  }

  Future<void> _onAllocate(
      AllocateBudgetToManager event, Emitter<HrApprovalsState> emit) async {
    final result =
        await repository.allocateBudget(event.managerId, event.points);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(state.copyWith(
          successMessage: 'Allocated ${event.points} points to manager')),
    );
  }

  Future<void> _onBulkAllocate(
      BulkAllocateBudgets event, Emitter<HrApprovalsState> emit) async {
    final result = await repository.bulkAllocateBudget(
        event.points, event.departmentId, event.roleFilter);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (count) =>
          emit(state.copyWith(successMessage: 'Allocated to $count wallets')),
    );
  }
}
