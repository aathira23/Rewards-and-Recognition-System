import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/nominations_repository.dart';

class ApproveNominationParams {
  final int nominationId;
  final String? comments;
  const ApproveNominationParams({required this.nominationId, this.comments});
}

class ApproveNominationUseCase
    implements UseCase<void, ApproveNominationParams> {
  final NominationsRepository repository;
  ApproveNominationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ApproveNominationParams params) async {
    return await repository.approveNomination(params.nominationId,
        comments: params.comments);
  }
}
