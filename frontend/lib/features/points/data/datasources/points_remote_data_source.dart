import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/points_summary_model.dart';
import '../models/point_transaction_model.dart';

abstract class PointsRemoteDataSource {
  Future<PointsSummaryModel> getPointsSummary();
  Future<(int, List<PointTransactionModel>)> getPointsHistory({
    int page = 1,
    String? category,
    String? startDate,
    String? endDate,
  });
  Future<List<Map<String, dynamic>>> getLeaderboard(
      {String period = 'MONTHLY'});
}

class PointsRemoteDataSourceImpl implements PointsRemoteDataSource {
  final ApiClient client;

  PointsRemoteDataSourceImpl({required this.client});

  @override
  Future<PointsSummaryModel> getPointsSummary() async {
    final response = await client.get(ApiConstants.userPoints);
    if (response.statusCode == 200) {
      // Backend returns { "data": { "balance": ... }, "message": ... }
      // ApiClient.get returns Response.
      // response.data is the body.
      // If our ApiClient unwraps it... let's check.
      // Usually ApiClient.get returns Dio Response.
      // Standard response format: data['data']
      return PointsSummaryModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to fetch points summary: ${response.statusCode}');
    }
  }

  @override
  Future<(int, List<PointTransactionModel>)> getPointsHistory({
    int page = 1,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final qp = <String, dynamic>{'page': page};
    if (category != null) qp['category'] = category;
    if (startDate != null) qp['start_date'] = startDate;
    if (endDate != null) qp['end_date'] = endDate;

    final response = await client.get(
      ApiConstants.pointsHistory,
      queryParameters: qp,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data['data'];
      final List historyList = data['history'] ?? [];
      final int total = (data['total'] as num?)?.toInt() ?? historyList.length;
      final items = historyList
          .map((json) => PointTransactionModel.fromJson(json))
          .toList();
      return (total, items);
    } else {
      throw Exception('Failed to fetch points history: ${response.statusCode}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLeaderboard(
      {String period = 'MONTHLY'}) async {
    final response = await client.get(
      ApiConstants.leaderboard,
      queryParameters: {'period': period, 'metric': 'POINTS', 'limit': 10},
    );
    if (response.statusCode == 200) {
      final List entries = response.data['data'];
      return entries.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch leaderboard: ${response.statusCode}');
    }
  }
}
