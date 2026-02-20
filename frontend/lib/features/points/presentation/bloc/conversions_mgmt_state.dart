import 'package:equatable/equatable.dart';

class ConversionsMgmtState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> pending;
  final String? error;
  final String? successMessage;

  const ConversionsMgmtState({
    this.isLoading = false,
    this.pending = const [],
    this.error,
    this.successMessage,
  });

  ConversionsMgmtState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? pending,
    String? error,
    String? successMessage,
  }) {
    return ConversionsMgmtState(
      isLoading: isLoading ?? this.isLoading,
      pending: pending ?? this.pending,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, pending, error, successMessage];
}
