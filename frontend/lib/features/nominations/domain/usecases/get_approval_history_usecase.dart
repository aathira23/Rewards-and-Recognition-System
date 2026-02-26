import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/nominations_repository.dart';

class GetApprovalHistoryUseCase
    implements UseCase<List<Map<String, dynamic>>, NoParams> {
  final NominationsRepository repository;
  GetApprovalHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(NoParams params) {
    return repository.getApprovalHistory();
  }
}
