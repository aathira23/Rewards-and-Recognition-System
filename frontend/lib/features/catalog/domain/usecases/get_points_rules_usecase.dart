import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/catalog_repository.dart';

class GetPointsRulesUseCase
    implements UseCase<List<Map<String, dynamic>>, NoParams> {
  final CatalogRepository repository;

  GetPointsRulesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      NoParams params) async {
    return await repository.getPointsRules();
  }
}
