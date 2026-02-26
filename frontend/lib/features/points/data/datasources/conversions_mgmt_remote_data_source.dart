import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class ConversionsMgmtRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchPendingConversions();
  Future<void> actionConversion(int id, String action);
}

class ConversionsMgmtRemoteDataSourceImpl
    implements ConversionsMgmtRemoteDataSource {
  final ApiClient client;
  ConversionsMgmtRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Map<String, dynamic>>> fetchPendingConversions() async {
    final response = await client.get(ApiConstants.pointsPendingConversions);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch pending conversions');
  }

  @override
  Future<void> actionConversion(int id, String action) async {
    await client.post(
      '${ApiConstants.pointsConversions}/$id/action',
      data: {'action': action},
    );
  }
}
