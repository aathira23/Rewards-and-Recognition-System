import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/repositories/conversions_mgmt_repository.dart';
import '../datasources/conversions_mgmt_remote_data_source.dart';

class ConversionsMgmtRepositoryImpl implements ConversionsMgmtRepository {
  final ConversionsMgmtRemoteDataSource remoteDataSource;
  ConversionsMgmtRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getPendingConversions() async {
    try {
      final result = await remoteDataSource.fetchPendingConversions();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> actionConversion(int id, String action) async {
    try {
      await remoteDataSource.actionConversion(id, action);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
