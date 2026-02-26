import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/catalog_repository.dart';

class SubmitConversionParams {
  final int points;
  final String type;

  SubmitConversionParams({required this.points, required this.type});
}

class SubmitConversionUseCase implements UseCase<bool, SubmitConversionParams> {
  final CatalogRepository repository;

  SubmitConversionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SubmitConversionParams params) async {
    return await repository.submitConversionRequest(params.points, params.type);
  }
}
