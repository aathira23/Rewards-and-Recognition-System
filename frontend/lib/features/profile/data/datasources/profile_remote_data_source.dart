import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

abstract class ProfileRemoteDataSource {
  /// Calls the backend /profile/me endpoint.
  Future<UserModel> getMe();

  /// Calls the backend /users/ endpoint.
  Future<(int, List<UserModel>)> getUsers({int page = 1, int perPage = 20});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient client;

  ProfileRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> getMe() async {
    final response = await client.get(
      ApiConstants.profile,
    );

    // Backend users_service.serialize_user is wrapped in a 'data' field by the response utility
    // response.data = { "data": { ...user_info... }, "message": "..." }
    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  @override
  Future<(int, List<UserModel>)> getUsers(
      {int page = 1, int perPage = 20}) async {
    final response = await client.get(
      ApiConstants.users,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> wrapper = response.data['data'];
      final List data = wrapper['items'] ?? [];
      final int total = (wrapper['total'] as num?)?.toInt() ?? data.length;
      final items = data.map((json) => UserModel.fromJson(json)).toList();
      return (total, items);
    } else {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }
  }
}
