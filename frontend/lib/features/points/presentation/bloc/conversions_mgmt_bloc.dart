import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/conversions_mgmt_repository.dart';
import 'conversions_mgmt_event.dart';
import 'conversions_mgmt_state.dart';

class ConversionsMgmtBloc
    extends Bloc<ConversionsMgmtEvent, ConversionsMgmtState> {
  final ConversionsMgmtRepository repository;

  ConversionsMgmtBloc({required this.repository})
      : super(const ConversionsMgmtState()) {
    on<LoadPendingConversions>(_onLoad);
    on<ActionConversionRequested>(_onAction);
  }

  Future<void> _onLoad(
      LoadPendingConversions event, Emitter<ConversionsMgmtState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getPendingConversions();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (data) => emit(state.copyWith(isLoading: false, pending: data)),
    );
  }

  Future<void> _onAction(ActionConversionRequested event,
      Emitter<ConversionsMgmtState> emit) async {
    final result = await repository.actionConversion(event.id, event.action);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) {
        emit(state.copyWith(
          successMessage: 'Conversion ${event.action.toLowerCase()}',
        ));
        add(LoadPendingConversions());
      },
    );
  }
}
