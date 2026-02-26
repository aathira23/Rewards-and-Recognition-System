import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recognition_entity.dart';
import '../repositories/recognitions_repository.dart';

class GetRecognitionFeedUseCase
    implements UseCase<List<RecognitionEntity>, NoParams> {
  final RecognitionsRepository repository;

  GetRecognitionFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<RecognitionEntity>>> call(NoParams params) async {
    return await repository.getRecognitionFeed();
  }
}
