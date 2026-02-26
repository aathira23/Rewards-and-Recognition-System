import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/analytics_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsModel> getDashboardMetrics({
    String? scope,
    String? fromDate,
    String? toDate,
  });
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final ApiClient client;
  AnalyticsRemoteDataSourceImpl({required this.client});

  @override
  Future<AnalyticsModel> getDashboardMetrics({
    String? scope,
    String? fromDate,
    String? toDate,
  }) async {
    final params = <String, dynamic>{};
    if (scope != null) params['scope'] = scope;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    final response = await client.get(
      ApiConstants.analytics,
      queryParameters: params,
    );
    if (response.statusCode == 200) {
      return AnalyticsModel.fromJson(response.data['data'] ?? {});
    }
    throw Exception('Failed to fetch analytics');
  }
}
