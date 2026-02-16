/// "Domain layer repository interface for Authentication."
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entity.dart';

abstract class AuthRepository {
  /// Signs in a user with email and password.
  /// Returns [AuthEntity] on success, or [Failure] on error.
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  });

  /// Logs out the user and clears the token.
  Future<Either<Failure, void>> logout();

  /// Checks if the user is currently authenticated.
  Future<bool> isAuthenticated();
}
