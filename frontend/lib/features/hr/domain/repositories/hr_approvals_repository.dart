import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class HrApprovalsRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> fetchNominations();
  Future<Either<Failure, void>> actionNomination(
      int id, String action, String? comments);

  Future<Either<Failure, List<Map<String, dynamic>>>> fetchConversions();
  Future<Either<Failure, void>> actionConversion(int id, String action);

  Future<Either<Failure, List<Map<String, dynamic>>>> fetchManagers();
  Future<Either<Failure, void>> allocateBudget(int managerId, int points);

  /// Returns the number of updated wallets.
  Future<Either<Failure, int>> bulkAllocateBudget(
      int points, int? departmentId, String? roleFilter);
}
