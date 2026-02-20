import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/budget_repository.dart';

class AllocateBudgetUseCase implements UseCase<void, AllocateBudgetParams> {
  final BudgetRepository repository;

  AllocateBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AllocateBudgetParams params) {
    return repository.allocateBudget(params.managerId, params.points);
  }
}

class AllocateBudgetParams extends Equatable {
  final int managerId;
  final int points;

  const AllocateBudgetParams({required this.managerId, required this.points});

  @override
  List<Object?> get props => [managerId, points];
}
