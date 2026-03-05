import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/budget_wallet_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetWalletUseCase implements UseCase<BudgetWalletEntity, NoParams> {
  final BudgetRepository repository;

  GetBudgetWalletUseCase(this.repository);

  @override
  Future<Either<Failure, BudgetWalletEntity>> call(NoParams params) {
    return repository.getWallet();
  }
}
