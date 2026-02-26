import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/user_mgmt_repository.dart';
import 'user_mgmt_event.dart';
import 'user_mgmt_state.dart';

class UserMgmtBloc extends Bloc<UserMgmtEvent, UserMgmtState> {
  final UserMgmtRepository repository;

  UserMgmtBloc({required this.repository}) : super(const UserMgmtState()) {
    on<LoadUsers>(_onLoad);
    on<CreateUserRequested>(_onCreate);
    on<UpdateUserRequested>(_onUpdate);
  }

  Future<void> _onLoad(LoadUsers event, Emitter<UserMgmtState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getUsers();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (data) => emit(state.copyWith(isLoading: false, users: data)),
    );
  }

  Future<void> _onCreate(
      CreateUserRequested event, Emitter<UserMgmtState> emit) async {
    final result = await repository.createUser(event.data);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        emit(state.copyWith(successMessage: 'User created successfully'));
        add(LoadUsers());
      },
    );
  }

  Future<void> _onUpdate(
      UpdateUserRequested event, Emitter<UserMgmtState> emit) async {
    final result = await repository.updateUser(event.id, event.data);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        emit(state.copyWith(successMessage: 'User updated successfully'));
        add(LoadUsers());
      },
    );
  }
}
