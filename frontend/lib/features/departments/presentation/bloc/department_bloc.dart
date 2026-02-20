import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_departments_usecase.dart';
import '../../domain/usecases/create_department_usecase.dart';
import '../../domain/usecases/update_department_usecase.dart';
import '../../domain/usecases/delete_department_usecase.dart';
import 'department_event.dart';
import 'department_state.dart';

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final GetDepartmentsUseCase getDepartmentsUseCase;
  final CreateDepartmentUseCase createDepartmentUseCase;
  final UpdateDepartmentUseCase updateDepartmentUseCase;
  final DeleteDepartmentUseCase deleteDepartmentUseCase;

  DepartmentBloc({
    required this.getDepartmentsUseCase,
    required this.createDepartmentUseCase,
    required this.updateDepartmentUseCase,
    required this.deleteDepartmentUseCase,
  }) : super(const DepartmentState()) {
    on<LoadDepartments>(_onLoad);
    on<CreateDepartment>(_onCreate);
    on<UpdateDepartment>(_onUpdate);
    on<DeleteDepartment>(_onDelete);
  }

  Future<void> _onLoad(
      LoadDepartments event, Emitter<DepartmentState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await getDepartmentsUseCase(NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (departments) =>
          emit(state.copyWith(isLoading: false, departments: departments)),
    );
  }

  Future<void> _onCreate(
      CreateDepartment event, Emitter<DepartmentState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result =
        await createDepartmentUseCase(CreateDepartmentParams(name: event.name));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) {
        emit(state.copyWith(
            isLoading: false, successMessage: 'Department created'));
        add(LoadDepartments());
      },
    );
  }

  Future<void> _onUpdate(
      UpdateDepartment event, Emitter<DepartmentState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await updateDepartmentUseCase(
        UpdateDepartmentParams(id: event.id, name: event.name));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) {
        emit(state.copyWith(
            isLoading: false, successMessage: 'Department updated'));
        add(LoadDepartments());
      },
    );
  }

  Future<void> _onDelete(
      DeleteDepartment event, Emitter<DepartmentState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result =
        await deleteDepartmentUseCase(DeleteDepartmentParams(id: event.id));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) {
        emit(state.copyWith(
            isLoading: false, successMessage: 'Department deleted'));
        add(LoadDepartments());
      },
    );
  }
}
