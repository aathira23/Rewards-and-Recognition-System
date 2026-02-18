import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notifications_repository.dart';

class MarkAsReadUseCase implements UseCase<void, int?> {
  final NotificationsRepository repository;
  MarkAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int? notificationId) async {
    return await repository.markAsRead(notificationId: notificationId);
  }
}
