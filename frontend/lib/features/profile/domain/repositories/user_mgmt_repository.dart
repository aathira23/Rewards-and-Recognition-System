import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class UserMgmtRepository {
  Future<Either<Failure, List<Map<String, dynamic>>>> getUsers();
  Future<Either<Failure, void>> createUser(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateUser(int id, Map<String, dynamic> data);
}
