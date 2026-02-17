/// "Events handled by the Authentication BLoC."
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check the current authentication status (e.g., on app start).
class AuthCheckRequested extends AuthEvent {}

/// Event to log in with email and password.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to fetch the user profile (called after successful login).
class AuthProfileFetchRequested extends AuthEvent {}

/// Event to log out.
class AuthLogoutRequested extends AuthEvent {}
