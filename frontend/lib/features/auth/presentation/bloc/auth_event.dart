/// "Events handled by the Authentication BLoC."
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Triggered on app startup to check if a user is already logged in.
class AuthCheckRequested extends AuthEvent {}

/// Triggered when the user submits their login credentials.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// Triggered when the user requests to log out.
class AuthLogoutRequested extends AuthEvent {}
