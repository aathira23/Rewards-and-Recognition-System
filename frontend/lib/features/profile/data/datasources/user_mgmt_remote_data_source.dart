import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

abstract class UserMgmtRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchUsers();
  Future<void> createUser(Map<String, dynamic> data);
  Future<void> updateUser(int id, Map<String, dynamic> data);
}

class UserMgmtRemoteDataSourceImpl implements UserMgmtRemoteDataSource {
  final ApiClient client;
  UserMgmtRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await client.get(ApiConstants.users);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch users');
  }

  @override
  Future<void> createUser(Map<String, dynamic> data) async {
    await client.post(ApiConstants.users, data: data);
  }

  @override
  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    await client.patch('${ApiConstants.userUpdate}$id', data: data);
  }
}
