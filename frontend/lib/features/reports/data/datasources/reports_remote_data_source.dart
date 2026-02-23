import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class ReportsRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchReport(
      Map<String, dynamic> queryParams);
  Future<List<int>> exportReportCsv(Map<String, dynamic> queryParams);
  Future<List<Map<String, dynamic>>> fetchPayroll(String month);
  Future<List<int>> exportPayrollCsv(String month);
  Future<List<Map<String, dynamic>>> fetchDepartments();
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final ApiClient client;

  ReportsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Map<String, dynamic>>> fetchReport(
      Map<String, dynamic> queryParams) async {
    final reportType = queryParams['report_type']?.toString();

    // PAYROLL uses a separate endpoint
    if (reportType == 'PAYROLL') {
      final month = queryParams['month']?.toString() ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      return fetchPayroll(month);
    }

    final params = <String, dynamic>{
      ...queryParams,
      'export_format': 'json',
    };
    final response =
        await client.get(ApiConstants.reports, queryParameters: params);
    final body = response.data;
    final raw = body['data']?['data'] ?? body['data'] ?? [];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Future<List<int>> exportReportCsv(Map<String, dynamic> queryParams) async {
    final reportType = queryParams['report_type']?.toString();

    if (reportType == 'PAYROLL') {
      final month = queryParams['month']?.toString() ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      return exportPayrollCsv(month);
    }

    final params = <String, dynamic>{
      ...queryParams,
      'export_format': 'csv',
    };
    final response = await client.get(
      ApiConstants.reports,
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPayroll(String month) async {
    final response = await client.get(ApiConstants.reportsPayroll,
        queryParameters: {'month': month, 'export_format': 'json'});
    final body = response.data;
    final raw = body['data']?['data'] ?? body['data'] ?? [];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Future<List<int>> exportPayrollCsv(String month) async {
    final response = await client.get(
      ApiConstants.reportsPayroll,
      queryParameters: {'month': month, 'export_format': 'csv'},
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final response = await client.get(ApiConstants.departments);
    final body = response.data;
    final list = body is Map ? (body['data'] ?? []) : body;
    if (list is List) return list.cast<Map<String, dynamic>>();
    return [];
  }
}
