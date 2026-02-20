import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/budget_wallet_model.dart';

abstract class BudgetRemoteDataSource {
  Future<BudgetWalletModel> getWallet();
  Future<void> allocateBudget(int managerId, int points);
  Future<void> rewardEmployee(int employeeId, int points, String reason);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final ApiClient client;

  BudgetRemoteDataSourceImpl({required this.client});

  @override
  Future<BudgetWalletModel> getWallet() async {
    final response = await client.get(ApiConstants.managerWallet);
    final data = response.data['data'] ?? response.data;
    return BudgetWalletModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  @override
  Future<void> allocateBudget(int managerId, int points) async {
    await client.post(ApiConstants.managerAllocate, data: {
      'manager_id': managerId,
      'points': points,
    });
  }

  @override
  Future<void> rewardEmployee(int employeeId, int points, String reason) async {
    await client.post(ApiConstants.managerReward, data: {
      'employee_id': employeeId,
      'points': points,
      'reason': reason,
    });
  }
}
