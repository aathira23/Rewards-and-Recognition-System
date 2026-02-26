import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/nominations_repository.dart';

class RejectNominationParams {
  final int nominationId;
  final String? comments;
  const RejectNominationParams({required this.nominationId, this.comments});
}

class RejectNominationUseCase implements UseCase<void, RejectNominationParams> {
  final NominationsRepository repository;
  RejectNominationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectNominationParams params) async {
    return await repository.rejectNomination(params.nominationId,
        comments: params.comments);
  }
}
