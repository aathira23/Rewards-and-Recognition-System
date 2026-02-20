import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/fetch_payroll_usecase.dart';
import '../../domain/usecases/export_payroll_csv_usecase.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final FetchPayrollUseCase fetchPayrollUseCase;
  final ExportPayrollCsvUseCase exportPayrollCsvUseCase;

  PayrollBloc({
    required this.fetchPayrollUseCase,
    required this.exportPayrollCsvUseCase,
  }) : super(const PayrollState()) {
    on<LoadPayroll>(_onLoad);
    on<ExportPayrollCsv>(_onExport);
  }

  Future<void> _onLoad(LoadPayroll event, Emitter<PayrollState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result =
        await fetchPayrollUseCase(FetchPayrollParams(month: event.month));
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) => emit(state.copyWith(isLoading: false, data: data)),
    );
  }

  Future<void> _onExport(
      ExportPayrollCsv event, Emitter<PayrollState> emit) async {
    final result = await exportPayrollCsvUseCase(
        ExportPayrollCsvParams(month: event.month));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(successMessage: 'CSV export initiated')),
    );
  }
}
