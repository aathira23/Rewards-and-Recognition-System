import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/celebration_model.dart';

abstract class CelebrationsRemoteDataSource {
  Future<List<CelebrationModel>> getUpcoming({int days = 30});
  Future<(int, List<CelebrationModel>)> getHistory(
      {int page = 1, int perPage = 20});
  Future<void> processToday();
}

class CelebrationsRemoteDataSourceImpl implements CelebrationsRemoteDataSource {
  final ApiClient client;
  CelebrationsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CelebrationModel>> getUpcoming({int days = 30}) async {
    final response = await client.get(
      ApiConstants.celebrationsUpcoming,
      queryParameters: {'days': days},
    );
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => CelebrationModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch upcoming celebrations');
  }

  @override
  Future<(int, List<CelebrationModel>)> getHistory(
      {int page = 1, int perPage = 20}) async {
    final response = await client.get(
      ApiConstants.celebrationsHistory,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> wrapper = response.data['data'];
      final List data = wrapper['items'] ?? [];
      final int total = (wrapper['total'] as num?)?.toInt() ?? data.length;
      final items =
          data.map((json) => CelebrationModel.fromJson(json)).toList();
      return (total, items);
    }
    throw Exception('Failed to fetch celebration history');
  }

  @override
  Future<void> processToday() async {
    await client.post(ApiConstants.celebrationsProcess);
  }
}
