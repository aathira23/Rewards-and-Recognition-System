import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/nomination_entity.dart';
import '../repositories/nominations_repository.dart';

class CreateNominationParams {
  final int nomineeId;
  final int awardTypeId;
  final String justification;
  const CreateNominationParams({
    required this.nomineeId,
    required this.awardTypeId,
    required this.justification,
  });
}

class CreateNominationUseCase
    implements UseCase<NominationEntity, CreateNominationParams> {
  final NominationsRepository repository;
  CreateNominationUseCase(this.repository);

  @override
  Future<Either<Failure, NominationEntity>> call(
      CreateNominationParams params) async {
    return await repository.createNomination(
      nomineeId: params.nomineeId,
      awardTypeId: params.awardTypeId,
      justification: params.justification,
    );
  }
}
