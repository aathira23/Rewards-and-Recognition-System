import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/celebration_entity.dart';

abstract class CelebrationsRepository {
  Future<Either<Failure, List<CelebrationEntity>>> getUpcoming({int days});
  Future<Either<Failure, List<CelebrationEntity>>> getHistory();
  Future<Either<Failure, void>> processToday();
}
