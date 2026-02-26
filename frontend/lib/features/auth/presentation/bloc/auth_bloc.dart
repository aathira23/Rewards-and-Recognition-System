/// "BLoC that manages the authentication state of the application."
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../profile/domain/usecases/get_me_usecase.dart';
import '../../../../core/usecases/usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetMeUseCase getMeUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.getMeUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthProfileFetchRequested>(_onAuthProfileFetchRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = await checkAuthStatusUseCase();
    if (isAuthenticated) {
      // Emit a temporary authenticated state with placeholder values.
      // The real user data will be populated by AuthProfileFetchRequested.
      // This allows the dashboard to render immediately while profile loads.
      emit(const AuthAuthenticated(
        auth: AuthEntity(
          token: '',
          userId: 0,
        ),
      ));
      add(AuthProfileFetchRequested());
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (auth) {
        emit(AuthAuthenticated(auth: auth));
        // Immediately fetch profile after successful login
        add(AuthProfileFetchRequested());
      },
    );
  }

  Future<void> _onAuthProfileFetchRequested(
    AuthProfileFetchRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentAuth = (state as AuthAuthenticated).auth;
      final result = await getMeUseCase(NoParams());

      result.fold(
        (failure) {
          // If profile fetch fails, we still keep them authenticated but maybe log a warning.
          // For now, we just keep the current state.
        },
        (user) {
          emit(AuthAuthenticated(
            auth: AuthEntity(
              token: currentAuth.token,
              userId: currentAuth.userId,
              user: user,
            ),
          ));
        },
      );
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }
}
