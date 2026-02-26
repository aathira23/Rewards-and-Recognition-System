import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadReport extends ReportsEvent {
  final Map<String, dynamic> queryParams;

  const LoadReport({required this.queryParams});

  @override
  List<Object?> get props => [queryParams];
}

class ExportReportCsv extends ReportsEvent {
  final Map<String, dynamic> queryParams;

  const ExportReportCsv({required this.queryParams});

  @override
  List<Object?> get props => [queryParams];
}

class LoadDepartmentsForFilter extends ReportsEvent {
  const LoadDepartmentsForFilter();
}

class ClearExportData extends ReportsEvent {
  const ClearExportData();
}
