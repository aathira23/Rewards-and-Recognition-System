import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/fetch_report_usecase.dart';
import '../../domain/usecases/export_report_csv_usecase.dart';
import '../../domain/usecases/fetch_departments_for_reports_usecase.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final FetchReportUseCase fetchReportUseCase;
  final ExportReportCsvUseCase exportReportCsvUseCase;
  final FetchDepartmentsForReportsUseCase fetchDepartmentsUseCase;

  ReportsBloc({
    required this.fetchReportUseCase,
    required this.exportReportCsvUseCase,
    required this.fetchDepartmentsUseCase,
  }) : super(const ReportsState()) {
    on<LoadReport>(_onLoad);
    on<ExportReportCsv>(_onExport);
    on<LoadDepartmentsForFilter>(_onLoadDepartments);
  }

  Future<void> _onLoad(LoadReport event, Emitter<ReportsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null, data: []));
    final result = await fetchReportUseCase(
        FetchReportParams(queryParams: event.queryParams));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) => emit(state.copyWith(isLoading: false, data: data)),
    );
  }

  Future<void> _onExport(
      ExportReportCsv event, Emitter<ReportsState> emit) async {
    final result = await exportReportCsvUseCase(
        ExportReportCsvParams(queryParams: event.queryParams));
    result.fold(
      (failure) => emit(
          state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(
          successMessage: 'CSV export initiated')),
    );
  }

  Future<void> _onLoadDepartments(
      LoadDepartmentsForFilter event, Emitter<ReportsState> emit) async {
    final result = await fetchDepartmentsUseCase(NoParams());
    result.fold(
      (_) {}, // silently ignore department load failures
      (departments) =>
          emit(state.copyWith(departments: departments)),
    );
  }
}
