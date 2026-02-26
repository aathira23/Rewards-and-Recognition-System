/// "States emitted by the Authentication BLoC."
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action is taken.
class AuthInitial extends AuthState {}

/// State during an active authentication process (e.g., logging in).
class AuthLoading extends AuthState {}

/// State when the user is successfully authenticated.
class AuthAuthenticated extends AuthState {
  final AuthEntity auth;

  const AuthAuthenticated({required this.auth});

  @override
  List<Object?> get props => [auth];
}

/// State when the user is not authenticated or has logged out.
class AuthUnauthenticated extends AuthState {}

/// State when an authentication operation fails.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
