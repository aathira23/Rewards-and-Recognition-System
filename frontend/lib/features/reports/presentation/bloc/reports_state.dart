import 'package:equatable/equatable.dart';

class ReportsState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> departments;
  final String? error;
  final String? successMessage;
  final List<int>? exportData;
  final String? exportFileName;

  const ReportsState({
    this.isLoading = false,
    this.data = const [],
    this.departments = const [],
    this.error,
    this.successMessage,
    this.exportData,
    this.exportFileName,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? data,
    List<Map<String, dynamic>>? departments,
    String? error,
    String? successMessage,
    List<int>? exportData,
    String? exportFileName,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      departments: departments ?? this.departments,
      error: error,
      successMessage: successMessage,
      exportData: exportData,
      exportFileName: exportFileName,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        data,
        departments,
        error,
        successMessage,
        exportData,
        exportFileName
      ];
}
