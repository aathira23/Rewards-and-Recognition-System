import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/budget_wallet_entity.dart';

abstract class BudgetRepository {
  Future<Either<Failure, BudgetWalletEntity>> getWallet();
  Future<Either<Failure, void>> allocateBudget(int managerId, int points);
  Future<Either<Failure, void>> rewardEmployee(
      int employeeId, int points, String reason);
}
