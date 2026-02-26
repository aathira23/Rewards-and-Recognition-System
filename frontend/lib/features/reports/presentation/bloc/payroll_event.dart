import 'package:equatable/equatable.dart';

abstract class PayrollEvent extends Equatable {
  const PayrollEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayroll extends PayrollEvent {
  final String month;
  const LoadPayroll({required this.month});

  @override
  List<Object?> get props => [month];
}

class ExportPayrollCsv extends PayrollEvent {
  final String month;
  const ExportPayrollCsv({required this.month});

  @override
  List<Object?> get props => [month];
}
