import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/budget_repository.dart';

class RewardEmployeeUseCase implements UseCase<void, RewardEmployeeParams> {
  final BudgetRepository repository;

  RewardEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RewardEmployeeParams params) {
    return repository.rewardEmployee(
        params.employeeId, params.points, params.reason);
  }
}

class RewardEmployeeParams extends Equatable {
  final int employeeId;
  final int points;
  final String reason;

  const RewardEmployeeParams({
    required this.employeeId,
    required this.points,
    required this.reason,
  });

  @override
  List<Object?> get props => [employeeId, points, reason];
}
