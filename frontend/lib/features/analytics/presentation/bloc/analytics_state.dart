import 'package:equatable/equatable.dart';
import '../../domain/entities/analytics_entity.dart';

enum AnalyticsStatus { initial, loading, success, failure }

class AnalyticsState extends Equatable {
  final AnalyticsStatus status;
  final AnalyticsEntity? data;
  final String? errorMessage;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.data,
    this.errorMessage,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    AnalyticsEntity? data,
    String? errorMessage,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
