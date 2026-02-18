import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:rr_frontend/core/presentation/models/nav_destination.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import 'package:rr_frontend/features/recognitions/presentation/pages/employee_recognitions_page.dart';
import 'package:rr_frontend/features/points/presentation/pages/points_page.dart';
import 'package:rr_frontend/features/catalog/presentation/pages/employee_rewards_page.dart';
import 'package:rr_frontend/features/nominations/presentation/pages/employee_approvals_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'User';
        String userRole = 'Employee';

        if (state is AuthAuthenticated && state.auth.user != null) {
          userName = state.auth.user!.name;
          userRole = state.auth.user!.role;
        }

        return MainLayout(
          userName: userName,
          userRole: userRole,
          destinations: const [
            NavDestination(
              title: 'Recognitions',
              icon: Icons.card_giftcard_rounded,
              page: EmployeeRecognitionsPage(),
            ),
            NavDestination(
              title: 'Points',
              icon: Icons.account_balance_wallet_rounded,
              page: PointsPage(),
            ),
            NavDestination(
              title: 'Rewards',
              icon: Icons.shopping_bag_rounded,
              page: EmployeeRewardsPage(),
            ),
            NavDestination(
              title: 'Approvals',
              icon: Icons.rule_rounded,
              page: EmployeeApprovalsPage(),
            ),
          ],
          onLogout: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
        );
      },
    );
  }
}
