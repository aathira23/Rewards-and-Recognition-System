import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/catalog_repository.dart';

class RedeemItemUseCase implements UseCase<bool, int> {
  final CatalogRepository repository;

  RedeemItemUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(int rewardId) async {
    return await repository.redeemItem(rewardId);
  }
}
