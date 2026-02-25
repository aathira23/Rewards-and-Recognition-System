import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract class HrApprovalsRemoteDataSource {
  /// Fetch all nominations.
  Future<List<Map<String, dynamic>>> fetchNominations();

  /// Approve or reject a nomination.
  Future<void> actionNomination(int id, String action, String? comments);

  /// Fetch all point conversion requests.
  Future<List<Map<String, dynamic>>> fetchConversions();

  /// Approve or reject a conversion request.
  Future<void> actionConversion(int id, String action);

  /// Fetch all users filtered to managers / dept heads.
  Future<List<Map<String, dynamic>>> fetchManagers();

  /// Individual budget allocation.
  Future<void> allocateBudget(int managerId, int points);

  /// Bulk budget allocation.
  Future<int> bulkAllocateBudget(
      int points, int? departmentId, String? roleFilter);
}

class HrApprovalsRemoteDataSourceImpl implements HrApprovalsRemoteDataSource {
  final ApiClient client;
  const HrApprovalsRemoteDataSourceImpl({required this.client});

  List<Map<String, dynamic>> _extractList(dynamic body) {
    final data = body is Map ? (body['data'] ?? []) : body;
    // Handle paginated response format: { items: [...], total: N }
    if (data is Map && data.containsKey('items')) {
      final items = data['items'];
      if (items is List) return items.cast<Map<String, dynamic>>();
      return <Map<String, dynamic>>[];
    }
    if (data is List) return data.cast<Map<String, dynamic>>();
    return <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchNominations() async {
    try {
      final res = await client.get(ApiConstants.nominations);
      return _extractList(res.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> actionNomination(int id, String action, String? comments) async {
    try {
      await client.post(
        '${ApiConstants.nominations}/$id/action',
        data: {
          'action': action,
          if (comments != null && comments.isNotEmpty) 'comments': comments,
        },
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConversions() async {
    try {
      final res = await client.get(ApiConstants.pointsConversions);
      return _extractList(res.data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> actionConversion(int id, String action) async {
    try {
      await client.post(
        '${ApiConstants.pointsConversions}/$id/action',
        data: {'action': action},
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchManagers() async {
    try {
      final res = await client.get(
        ApiConstants.users,
        queryParameters: {'per_page': 100},
      );
      final raw = res.data['data'] ?? res.data ?? [];
      // Handle paginated response: { items: [...], total: N }
      List<Map<String, dynamic>> all;
      if (raw is Map && raw.containsKey('items')) {
        final items = raw['items'];
        all = (items is List)
            ? items.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
      } else if (raw is List) {
        all = raw.cast<Map<String, dynamic>>();
      } else {
        all = <Map<String, dynamic>>[];
      }
      return all
          .where((u) =>
              (u['role']?.toString().toUpperCase() == 'MANAGER') ||
              (u['role']?.toString().toUpperCase() == 'DEPT_HEAD'))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> allocateBudget(int managerId, int points) async {
    try {
      await client.post(ApiConstants.managerAllocate,
          data: {'manager_id': managerId, 'points': points});
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<int> bulkAllocateBudget(
      int points, int? departmentId, String? roleFilter) async {
    try {
      final data = <String, dynamic>{'points': points};
      if (departmentId != null) data['department_id'] = departmentId;
      if (roleFilter != null) data['role_filter'] = roleFilter;
      final res =
          await client.post(ApiConstants.managerBulkAllocate, data: data);
      return res.data['data']?['updated_wallets'] ?? 0;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
