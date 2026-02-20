import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_system_configs_usecase.dart';
import '../../domain/usecases/get_points_rules_config_usecase.dart';
import '../../domain/usecases/update_system_config_usecase.dart';
import 'config_event.dart';
import 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final GetSystemConfigsUseCase getSystemConfigsUseCase;
  final GetPointsRulesConfigUseCase getPointsRulesConfigUseCase;
  final UpdateSystemConfigUseCase updateSystemConfigUseCase;

  ConfigBloc({
    required this.getSystemConfigsUseCase,
    required this.getPointsRulesConfigUseCase,
    required this.updateSystemConfigUseCase,
  }) : super(const ConfigState()) {
    on<LoadConfig>(_onLoad);
    on<UpdateConfigEntry>(_onUpdate);
  }

  Future<void> _onLoad(LoadConfig event, Emitter<ConfigState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final configResult = await getSystemConfigsUseCase(NoParams());
    final rulesResult = await getPointsRulesConfigUseCase(NoParams());

    configResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (configs) {
        rulesResult.fold(
          (failure) => emit(state.copyWith(
              isLoading: false, configs: configs, error: failure.message)),
          (rules) => emit(
              state.copyWith(isLoading: false, configs: configs, rules: rules)),
        );
      },
    );
  }

  Future<void> _onUpdate(
      UpdateConfigEntry event, Emitter<ConfigState> emit) async {
    final result = await updateSystemConfigUseCase(
        UpdateSystemConfigParams(key: event.key, value: event.value));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: 'Config updated'));
        add(LoadConfig());
      },
    );
  }
}
