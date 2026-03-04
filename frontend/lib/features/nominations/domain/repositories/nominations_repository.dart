import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/nomination_entity.dart';
import '../entities/award_type_entity.dart';

abstract class NominationsRepository {
  Future<Either<Failure, List<AwardTypeEntity>>> getAwardTypes();
  Future<Either<Failure, List<NominationEntity>>> getNominations();
  Future<Either<Failure, NominationEntity>> createNomination({
    required int nomineeId,
    required int awardTypeId,
    required String citation,
  });
  Future<Either<Failure, void>> approveNomination(int nominationId,
      {String? comments});
  Future<Either<Failure, void>> rejectNomination(int nominationId,
      {String? comments});
  Future<Either<Failure, AwardTypeEntity>> createAwardType({
    required String awardKey,
    required String name,
    required int points,
    required String frequency,
    required String eligibilityRule,
    String? description,
    List<String>? approvalWorkflow,
  });
  Future<Either<Failure, AwardTypeEntity>> updateAwardType(
    int id, {
    String? name,
    int? points,
    String? description,
  });
  Future<Either<Failure, List<Map<String, dynamic>>>> getApprovalHistory();
}
