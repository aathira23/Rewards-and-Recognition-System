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
      // 1. Fetch all users and filter to MANAGER / DEPT_HEAD
      final res = await client.get(
        ApiConstants.users,
        queryParameters: {'per_page': 100},
      );
      final raw = res.data['data'] ?? res.data ?? [];
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
      final managers = all
          .where((u) =>
              (u['role']?.toString().toUpperCase() == 'MANAGER') ||
              (u['role']?.toString().toUpperCase() == 'DEPT_HEAD'))
          .toList();

      // 2. Fetch wallet utilization report to get actual wallet balances
      try {
        final walletRes = await client.get(
          ApiConstants.reports,
          queryParameters: {'report_type': 'WALLET_UTILIZATION'},
        );
        final reportData = walletRes.data['data']?['data'];
        if (reportData is List) {
          // Build a lookup map: manager_id -> remaining_balance
          final balanceMap = <int, int>{};
          for (final row in reportData) {
            final id = row['manager_id'];
            final balance = row['remaining_balance'];
            if (id != null && balance != null) {
              balanceMap[id as int] = (balance as num).toInt();
            }
          }
          // Enrich manager entries with their wallet balance
          for (var i = 0; i < managers.length; i++) {
            final id = managers[i]['id'] as int?;
            managers[i] = {
              ...managers[i],
              'wallet': {'balance': id != null ? (balanceMap[id] ?? 0) : 0},
            };
          }
        }
      } catch (_) {
        // Wallet enrichment is best-effort; show 0 on failure
        for (var i = 0; i < managers.length; i++) {
          managers[i] = {
            ...managers[i],
            'wallet': {'balance': 0}
          };
        }
      }

      return managers;
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
