import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/nomination_entity.dart';
import '../repositories/nominations_repository.dart';

class GetNominationsUseCase
    implements UseCase<List<NominationEntity>, NoParams> {
  final NominationsRepository repository;
  GetNominationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NominationEntity>>> call(NoParams params) async {
    return await repository.getNominations();
  }
}
