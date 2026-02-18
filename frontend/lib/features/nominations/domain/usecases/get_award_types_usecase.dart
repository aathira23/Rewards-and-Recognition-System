import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/award_type_entity.dart';
import '../repositories/nominations_repository.dart';

class GetAwardTypesUseCase implements UseCase<List<AwardTypeEntity>, NoParams> {
  final NominationsRepository repository;
  GetAwardTypesUseCase(this.repository);

  @override
  Future<Either<Failure, List<AwardTypeEntity>>> call(NoParams params) async {
    return await repository.getAwardTypes();
  }
}
