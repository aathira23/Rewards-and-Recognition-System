/// "The root widget of the application, configuring themes, localizations, and initial navigation."
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/network/auth_interceptor.dart';
import 'package:rr_frontend/core/theme/app_theme.dart';
import 'package:rr_frontend/features/analytics/presentation/pages/dashboard_page.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:rr_frontend/features/auth/presentation/pages/login_page.dart';
import 'package:rr_frontend/injection_container.dart';

class RRApp extends StatelessWidget {
  const RRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final authBloc = sl<AuthBloc>()..add(AuthCheckRequested());
        // Wire 401 handler: when any API call gets Unauthorized,
        // dispatch logout so the UI returns to the login screen.
        sl<AuthInterceptor>().onUnauthorized = () {
          authBloc.add(AuthLogoutRequested());
        };
        return authBloc;
      },
      child: MaterialApp(
        title: 'Rewards & Recognition',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) =>
              current is AuthAuthenticated ||
              current is AuthUnauthenticated ||
              current is AuthInitial ||
              (previous is AuthInitial && current is AuthLoading),
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final user = state.auth.user;
              if (user == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return DashboardPage(
                userName: user.name,
                userRole: user.role,
              );
            }
            if (state is AuthInitial || (state is AuthLoading)) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
