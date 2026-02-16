/// "Entity representing the authentication status and token."
import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String token;
  final int userId;

  const AuthEntity({
    required this.token,
    required this.userId,
  });

  @override
  List<Object?> get props => [token, userId];
}
