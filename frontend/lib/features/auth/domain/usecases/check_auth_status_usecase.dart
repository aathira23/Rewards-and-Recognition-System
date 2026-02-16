/// "Use case for checking if the user is currently authenticated on app startup."
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  /// Note: This doesn't follow the standard UseCase pattern
  /// because it returns a simple bool (no Either/Failure expected here).
  Future<bool> call() async {
    return await repository.isAuthenticated();
  }
}
