import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class ReportsRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchReport(
      Map<String, dynamic> queryParams);
  Future<Either<Failure, void>> exportReportCsv(
      Map<String, dynamic> queryParams);
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchPayroll(
      String month);
  Future<Either<Failure, void>> exportPayrollCsv(String month);
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchDepartments();
}
