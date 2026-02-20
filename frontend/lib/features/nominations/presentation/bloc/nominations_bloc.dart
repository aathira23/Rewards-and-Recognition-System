import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_award_types_usecase.dart';
import '../../domain/usecases/get_nominations_usecase.dart';
import '../../domain/usecases/create_nomination_usecase.dart';
import '../../domain/usecases/approve_nomination_usecase.dart';
import '../../domain/usecases/reject_nomination_usecase.dart';
import '../../domain/usecases/get_approval_history_usecase.dart';
import '../../../profile/domain/usecases/get_users_usecase.dart';
import 'nominations_event.dart';
import 'nominations_state.dart';

class NominationsBloc extends Bloc<NominationsEvent, NominationsState> {
  final GetAwardTypesUseCase getAwardTypesUseCase;
  final GetNominationsUseCase getNominationsUseCase;
  final CreateNominationUseCase createNominationUseCase;
  final ApproveNominationUseCase approveNominationUseCase;
  final RejectNominationUseCase rejectNominationUseCase;
  final GetApprovalHistoryUseCase getApprovalHistoryUseCase;
  final GetUsersUseCase getUsersUseCase;

  NominationsBloc({
    required this.getAwardTypesUseCase,
    required this.getNominationsUseCase,
    required this.createNominationUseCase,
    required this.approveNominationUseCase,
    required this.rejectNominationUseCase,
    required this.getApprovalHistoryUseCase,
    required this.getUsersUseCase,
  }) : super(const NominationsState()) {
    on<GetAwardTypesRequested>(_onGetAwardTypes);
    on<GetUsersRequested>(_onGetUsers);
    on<GetNominationsRequested>(_onGetNominations);
    on<CreateNominationRequested>(_onCreateNomination);
    on<ApproveNominationRequested>(_onApprove);
    on<RejectNominationRequested>(_onReject);
    on<GetApprovalHistoryRequested>(_onGetApprovalHistory);
  }

  Future<void> _onGetAwardTypes(
      GetAwardTypesRequested event, Emitter<NominationsState> emit) async {
    final result = await getAwardTypesUseCase(NoParams());
    result.fold(
      (f) => emit(state.copyWith(
          status: NominationsStatus.failure, errorMessage: f.message)),
      (types) => emit(
          state.copyWith(status: NominationsStatus.success, awardTypes: types)),
    );
  }

  Future<void> _onGetUsers(
      GetUsersRequested event, Emitter<NominationsState> emit) async {
    final result = await getUsersUseCase(NoParams());
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (users) => emit(state.copyWith(users: users)),
    );
  }

  Future<void> _onGetNominations(
      GetNominationsRequested event, Emitter<NominationsState> emit) async {
    emit(state.copyWith(status: NominationsStatus.loading));
    final result = await getNominationsUseCase(NoParams());
    result.fold(
      (f) => emit(state.copyWith(
          status: NominationsStatus.failure, errorMessage: f.message)),
      (noms) => emit(
          state.copyWith(status: NominationsStatus.success, nominations: noms)),
    );
  }

  Future<void> _onCreateNomination(
      CreateNominationRequested event, Emitter<NominationsState> emit) async {
    emit(state.copyWith(status: NominationsStatus.loading));
    final result = await createNominationUseCase(CreateNominationParams(
      nomineeId: event.nomineeId,
      awardTypeId: event.awardTypeId,
      justification: event.justification,
    ));
    result.fold(
      (f) => emit(state.copyWith(
          status: NominationsStatus.failure, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(
            status: NominationsStatus.success,
            successMessage: 'Nomination submitted successfully'));
        add(GetNominationsRequested());
      },
    );
  }

  Future<void> _onApprove(
      ApproveNominationRequested event, Emitter<NominationsState> emit) async {
    final result = await approveNominationUseCase(ApproveNominationParams(
        nominationId: event.nominationId, comments: event.comments));
    result.fold(
      (f) => emit(state.copyWith(
          status: NominationsStatus.failure, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(
            status: NominationsStatus.success,
            successMessage: 'Nomination approved'));
        add(GetNominationsRequested());
        add(GetApprovalHistoryRequested());
      },
    );
  }

  Future<void> _onReject(
      RejectNominationRequested event, Emitter<NominationsState> emit) async {
    final result = await rejectNominationUseCase(RejectNominationParams(
        nominationId: event.nominationId, comments: event.comments));
    result.fold(
      (f) => emit(state.copyWith(
          status: NominationsStatus.failure, errorMessage: f.message)),
      (_) {
        emit(state.copyWith(
            status: NominationsStatus.success,
            successMessage: 'Nomination rejected'));
        add(GetNominationsRequested());
        add(GetApprovalHistoryRequested());
      },
    );
  }

  Future<void> _onGetApprovalHistory(
      GetApprovalHistoryRequested event, Emitter<NominationsState> emit) async {
    emit(state.copyWith(historyLoading: true));
    final result = await getApprovalHistoryUseCase(NoParams());
    result.fold(
      (f) =>
          emit(state.copyWith(historyLoading: false, errorMessage: f.message)),
      (history) =>
          emit(state.copyWith(historyLoading: false, approvalHistory: history)),
    );
  }
}
