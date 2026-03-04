import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_catalog_items_usecase.dart';
import '../../domain/usecases/redeem_item_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/submit_conversion_usecase.dart';
import '../../domain/usecases/get_points_rules_usecase.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final GetCatalogItemsUseCase getCatalogItemsUseCase;
  final RedeemItemUseCase redeemItemUseCase;
  final GetHistoryUseCase getHistoryUseCase;
  final SubmitConversionUseCase submitConversionUseCase;
  final GetPointsRulesUseCase getPointsRulesUseCase;

  CatalogBloc({
    required this.getCatalogItemsUseCase,
    required this.redeemItemUseCase,
    required this.getHistoryUseCase,
    required this.submitConversionUseCase,
    required this.getPointsRulesUseCase,
  }) : super(const CatalogState()) {
    on<GetCatalogItemsRequested>(_onGetCatalogItemsRequested);
    on<RedeemItemRequested>(_onRedeemItemRequested);
    on<GetHistoryRequested>(_onGetHistoryRequested);
    on<SubmitConversionRequested>(_onSubmitConversionRequested);
    on<GetPointsRulesRequested>(_onGetPointsRulesRequested);
  }

  Future<void> _onGetPointsRulesRequested(
    GetPointsRulesRequested event,
    Emitter<CatalogState> emit,
  ) async {
    final result = await getPointsRulesUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (rules) => emit(state.copyWith(pointsRules: rules)),
    );
  }

  Future<void> _onGetCatalogItemsRequested(
    GetCatalogItemsRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await getCatalogItemsUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: CatalogStatus.success,
        items: items,
      )),
    );
  }

  Future<void> _onGetHistoryRequested(
    GetHistoryRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await getHistoryUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: failure.message,
      )),
      (history) => emit(state.copyWith(
        status: CatalogStatus.success,
        redemptions: List.from(history['redemptions']!),
        conversions: List.from(history['conversions']!),
      )),
    );
  }

  Future<void> _onRedeemItemRequested(
    RedeemItemRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await redeemItemUseCase(event.rewardId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: failure.message,
      )),
      (success) => emit(state.copyWith(
        status: CatalogStatus.success,
        redemptionSuccess: success,
      )),
    );
  }

  Future<void> _onSubmitConversionRequested(
    SubmitConversionRequested event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await submitConversionUseCase(
      SubmitConversionParams(points: event.points, type: event.type),
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: CatalogStatus.failure,
        errorMessage: failure.message,
      )),
      (success) => emit(state.copyWith(
        status: CatalogStatus.success,
        conversionSuccess: success,
      )),
    );
  }
}
