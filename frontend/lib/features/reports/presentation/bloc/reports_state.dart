import 'package:equatable/equatable.dart';

class ReportsState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> departments;
  final String? error;
  final String? successMessage;

  const ReportsState({
    this.isLoading = false,
    this.data = const [],
    this.departments = const [],
    this.error,
    this.successMessage,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? data,
    List<Map<String, dynamic>>? departments,
    String? error,
    String? successMessage,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      departments: departments ?? this.departments,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, data, departments, error, successMessage];
}
