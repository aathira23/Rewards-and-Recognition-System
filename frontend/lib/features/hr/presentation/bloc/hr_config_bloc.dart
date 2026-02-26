import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';
import '../../domain/usecases/load_all_hr_config_usecase.dart';
import '../../domain/usecases/save_hr_config_item_usecase.dart';
import '../../domain/usecases/toggle_hr_config_item_usecase.dart';
import '../../domain/usecases/update_hr_config_setting_usecase.dart';
import 'hr_config_event.dart';
import 'hr_config_state.dart';

class HrConfigBloc extends Bloc<HrConfigEvent, HrConfigState> {
  final LoadAllHrConfigUseCase loadAllUseCase;
  final SaveHrConfigItemUseCase saveItemUseCase;
  final ToggleHrConfigItemUseCase toggleItemUseCase;
  final UpdateHrConfigSettingUseCase updateSettingUseCase;

  HrConfigBloc({
    required this.loadAllUseCase,
    required this.saveItemUseCase,
    required this.toggleItemUseCase,
    required this.updateSettingUseCase,
  }) : super(const HrConfigState()) {
    on<LoadAllHrConfig>(_onLoadAll);
    on<SaveItem>(_onSaveItem);
    on<ToggleItem>(_onToggleItem);
    on<UpdateConfigSetting>(_onUpdateSetting);
  }

  Future<void> _onLoadAll(
      LoadAllHrConfig event, Emitter<HrConfigState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await loadAllUseCase(NoParams());
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) => emit(state.copyWith(
        isLoading: false,
        awardTypes: data.awardTypes,
        badges: data.badges,
        rewards: data.rewards,
        policies: data.policies,
        configs: data.configs,
      )),
    );
  }

  Future<void> _onSaveItem(SaveItem event, Emitter<HrConfigState> emit) async {
    final result = await saveItemUseCase(SaveHrConfigItemParams(
      entityType: event.entityType,
      data: event.data,
      id: event.id,
    ));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: 'Saved successfully'));
        add(LoadAllHrConfig());
      },
    );
  }

  Future<void> _onToggleItem(
      ToggleItem event, Emitter<HrConfigState> emit) async {
    // Optimistic update
    final newActive = !event.currentlyActive;
    _optimisticToggle(event.entityType, event.id, newActive, emit);

    final result = await toggleItemUseCase(ToggleHrConfigItemParams(
      entityType: event.entityType,
      id: event.id,
      newActive: newActive,
    ));
    result.fold(
      (failure) {
        // Revert on failure
        _optimisticToggle(
            event.entityType, event.id, event.currentlyActive, emit);
        emit(state.copyWith(error: failure.message));
      },
      (_) {
        final label = newActive ? 'activated' : 'deactivated';
        emit(state.copyWith(
            successMessage: '${_entityLabel(event.entityType)} $label'));
      },
    );
  }

  Future<void> _onUpdateSetting(
      UpdateConfigSetting event, Emitter<HrConfigState> emit) async {
    final result = await updateSettingUseCase(
        UpdateHrConfigSettingParams(key: event.key, value: event.value));
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        emit(state.copyWith(successMessage: 'Setting updated'));
        add(LoadAllHrConfig());
      },
    );
  }

  // ── helpers ──────────────────────────────────────────────────────
  void _optimisticToggle(HrConfigEntityType entityType, int id, bool active,
      Emitter<HrConfigState> emit) {
    switch (entityType) {
      case HrConfigEntityType.awardType:
        emit(state.copyWith(
            awardTypes: _toggleInList(state.awardTypes, id, active)));
        break;
      case HrConfigEntityType.badge:
        emit(state.copyWith(badges: _toggleInList(state.badges, id, active)));
        break;
      case HrConfigEntityType.reward:
        emit(state.copyWith(rewards: _toggleInList(state.rewards, id, active)));
        break;
      case HrConfigEntityType.policyRule:
        emit(state.copyWith(
            policies: _toggleInList(state.policies, id, active)));
        break;
    }
  }

  List<Map<String, dynamic>> _toggleInList(
      List<Map<String, dynamic>> list, int id, bool active) {
    return list.map((item) {
      if (item['id'] == id) return {...item, 'is_active': active};
      return item;
    }).toList();
  }

  String _entityLabel(HrConfigEntityType type) {
    switch (type) {
      case HrConfigEntityType.awardType:
        return 'Award type';
      case HrConfigEntityType.badge:
        return 'Badge';
      case HrConfigEntityType.reward:
        return 'Reward';
      case HrConfigEntityType.policyRule:
        return 'Policy rule';
    }
  }
}
