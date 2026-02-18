import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/celebration_model.dart';

abstract class CelebrationsRemoteDataSource {
  Future<List<CelebrationModel>> getUpcoming({int days = 30});
  Future<List<CelebrationModel>> getHistory();
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
  Future<List<CelebrationModel>> getHistory() async {
    final response = await client.get(ApiConstants.celebrationsHistory);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => CelebrationModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch celebration history');
  }

  @override
  Future<void> processToday() async {
    await client.post(ApiConstants.celebrationsProcess);
  }
}
