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
    // Auto-paginate to fetch all users for management views.
    List<Map<String, dynamic>> allUsers = [];
    int page = 1;
    while (true) {
      final response = await client.get(
        ApiConstants.users,
        queryParameters: {'page': page, 'per_page': 100},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users');
      }
      final Map<String, dynamic> wrapper = response.data['data'];
      final List data = wrapper['items'] ?? [];
      final int total = (wrapper['total'] as num?)?.toInt() ?? data.length;
      allUsers.addAll(data.cast<Map<String, dynamic>>());
      if (allUsers.length >= total) break;
      page++;
    }
    return allUsers;
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
