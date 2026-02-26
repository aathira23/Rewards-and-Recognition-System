import 'package:equatable/equatable.dart';

class PayrollState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> data;
  final String? error;
  final String? successMessage;

  const PayrollState({
    this.isLoading = false,
    this.data = const [],
    this.error,
    this.successMessage,
  });

  PayrollState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? data,
    String? error,
    String? successMessage,
  }) {
    return PayrollState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, error, successMessage];
}
