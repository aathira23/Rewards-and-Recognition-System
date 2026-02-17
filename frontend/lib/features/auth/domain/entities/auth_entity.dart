/// "Entity representing the authentication status and token."
import 'package:equatable/equatable.dart';

import 'package:rr_frontend/features/profile/domain/entities/user_entity.dart';

class AuthEntity extends Equatable {
  final String token;
  final int userId;
  final UserEntity? user;

  const AuthEntity({
    required this.token,
    required this.userId,
    this.user,
  });

  @override
  List<Object?> get props => [token, userId, user];
}
