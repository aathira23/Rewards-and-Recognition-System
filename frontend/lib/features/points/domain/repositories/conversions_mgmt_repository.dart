import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class ConversionsMgmtRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getPendingConversions();
  Future<Either<Failure, void>> actionConversion(int id, String action);
}
