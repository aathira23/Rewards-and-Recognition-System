import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../domain/repositories/nominations_repository.dart';
import '../datasources/nominations_remote_data_source.dart';

class NominationsRepositoryImpl implements NominationsRepository {
  final NominationsRemoteDataSource remoteDataSource;
  NominationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AwardTypeEntity>>> getAwardTypes() async {
    try {
      final result = await remoteDataSource.getAwardTypes();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NominationEntity>>> getNominations() async {
    try {
      final (_, items) = await remoteDataSource.getNominations(perPage: 100);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NominationEntity>> createNomination({
    required int nomineeId,
    required int awardTypeId,
    required String citation,
    String? personaType,
    String? personaLabel,
  }) async {
    try {
      final result = await remoteDataSource.createNomination(
        nomineeId: nomineeId,
        awardTypeId: awardTypeId,
        citation: citation,
        personaType: personaType,
        personaLabel: personaLabel,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveNomination(int nominationId,
      {String? comments}) async {
    try {
      await remoteDataSource.approveNomination(nominationId,
          comments: comments);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectNomination(int nominationId,
      {String? comments}) async {
    try {
      await remoteDataSource.rejectNomination(nominationId, comments: comments);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AwardTypeEntity>> createAwardType({
    required String awardKey,
    required String name,
    required int points,
    required String frequency,
    required String eligibilityRule,
    String? description,
    List<String>? approvalWorkflow,
  }) async {
    try {
      final result = await remoteDataSource.createAwardType({
        'award_key': awardKey,
        'name': name,
        'points': points,
        'frequency': frequency,
        'eligibility_rule': eligibilityRule,
        if (description != null) 'description': description,
        if (approvalWorkflow != null) 'approval_workflow': approvalWorkflow,
      });
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AwardTypeEntity>> updateAwardType(
    int id, {
    String? name,
    int? points,
    String? description,
  }) async {
    try {
      final result = await remoteDataSource.updateAwardType(id, {
        if (name != null) 'name': name,
        if (points != null) 'points': points,
        if (description != null) 'description': description,
      });
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getApprovalHistory() async {
    try {
      final result = await remoteDataSource.fetchApprovalHistory();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
