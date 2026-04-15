/// Use case for logging in with a raw Styria Bearer token (dev / testing only).
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class TokenLoginParams {
  final String token;
  TokenLoginParams({required this.token});
}

class TokenLoginUseCase {
  final AuthRepository repository;
  TokenLoginUseCase(this.repository);

  Future<Either<Failure, AuthEntity>> call(TokenLoginParams params) async {
    return await repository.tokenLogin(token: params.token);
  }
}
