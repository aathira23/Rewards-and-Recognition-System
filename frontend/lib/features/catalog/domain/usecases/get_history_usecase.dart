import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/catalog_repository.dart';

class GetHistoryUseCase implements UseCase<Map<String, List>, NoParams> {
  final CatalogRepository repository;

  GetHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, List>>> call(NoParams params) async {
    return await repository.getHistory();
  }
}
