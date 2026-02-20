/// "The root widget of the application, configuring themes, localizations, and initial navigation."
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'Rewards & Recognition',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: BlocBuilder<AuthBloc, AuthState>(
          // Only rebuild for real routing decisions.
          // AuthLoading / AuthFailure during a login attempt must NOT
          // rebuild this widget — that would replace LoginPage with a
          // fresh instance and clear the text fields.
          buildWhen: (previous, current) =>
              current is AuthAuthenticated ||
              current is AuthUnauthenticated ||
              current is AuthInitial ||
              // Show the initial app-start spinner only when the very
              // first check is in progress (previous is AuthInitial).
              (previous is AuthInitial && current is AuthLoading),
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              final user = state.auth.user;
              return DashboardPage(
                userName: user?.name ?? 'User',
                userRole: user?.role ?? 'EMPLOYEE',
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
