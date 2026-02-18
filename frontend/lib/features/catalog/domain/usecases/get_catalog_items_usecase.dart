import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reward_entity.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogItemsUseCase implements UseCase<List<RewardEntity>, NoParams> {
  final CatalogRepository repository;

  GetCatalogItemsUseCase(this.repository);

  @override
  Future<Either<Failure, List<RewardEntity>>> call(NoParams params) async {
    return await repository.getCatalogItems();
  }
}
