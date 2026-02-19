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
import 'package:rr_frontend/features/nominations/presentation/pages/employee_nominations_page.dart';
import 'package:rr_frontend/features/nominations/presentation/pages/manager_approvals_page.dart';
import 'package:rr_frontend/features/analytics/presentation/pages/analytics_page.dart';
import 'package:rr_frontend/features/reports/presentation/pages/reports_page.dart';
import 'package:rr_frontend/features/hr/presentation/pages/hr_config_page.dart';
import 'package:rr_frontend/features/hr/presentation/pages/hr_approvals_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'User';
        String userRole = 'EMPLOYEE';

        if (state is AuthAuthenticated && state.auth.user != null) {
          userName = state.auth.user!.name;
          userRole = state.auth.user!.role;
        }

        final destinations = _buildDestinations(userRole);

        return MainLayout(
          userName: userName,
          userRole: _displayRole(userRole),
          destinations: destinations,
          onLogout: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
        );
      },
    );
  }

  /// Returns a human-readable role label for the sidebar.
  String _displayRole(String role) {
    switch (role.toUpperCase()) {
      case 'HR':
        return 'HR Admin';
      case 'DEPT_HEAD':
        return 'Department Head';
      case 'MANAGER':
        return 'Manager';
      default:
        return 'Employee';
    }
  }

  /// Builds the navigation destinations based on the user's role.
  ///
  /// EMPLOYEE  → Recognitions, Points, Rewards, Nominations (nominate & view status/received)
  /// MANAGER   → Recognitions, Points, Rewards, Approvals (approve/reject + nominate), Analytics
  /// DEPT_HEAD → Same as Manager
  /// HR        → Analytics (ORG), Reports, Configuration, Approvals & Allocation
  ///
  /// Celebrations surface via the notification bell inbox (celebration-type notifications).
  List<NavDestination> _buildDestinations(String role) {
    final r = role.toUpperCase();

    // ── HR ────────────────────────────────────────────────────────
    if (r == 'HR') {
      return [
        NavDestination(
          title: 'Analytics',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
        const NavDestination(
          title: 'Reports',
          icon: Icons.summarize_rounded,
          page: ReportsPage(),
        ),
        const NavDestination(
          title: 'Configuration',
          icon: Icons.tune_rounded,
          page: HrConfigPage(),
        ),
        const NavDestination(
          title: 'Approvals & Allocation',
          icon: Icons.task_alt_rounded,
          page: HrApprovalsPage(),
        ),
      ];
    }

    // ── MANAGER / DEPT_HEAD ───────────────────────────────────────
    if (r == 'MANAGER' || r == 'DEPT_HEAD') {
      return [
        const NavDestination(
          title: 'Recognitions',
          icon: Icons.card_giftcard_rounded,
          page: EmployeeRecognitionsPage(),
        ),
        NavDestination(
          title: 'Points',
          icon: Icons.account_balance_wallet_rounded,
          page: PointsPage(userRole: r),
        ),
        const NavDestination(
          title: 'Rewards',
          icon: Icons.shopping_bag_rounded,
          page: EmployeeRewardsPage(),
        ),
        const NavDestination(
          title: 'Approvals',
          icon: Icons.task_alt_rounded,
          page: ManagerApprovalsPage(),
        ),
        NavDestination(
          title: 'Analytics',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
      ];
    }

    // ── EMPLOYEE ──────────────────────────────────────────────────
    return [
      const NavDestination(
        title: 'Recognitions',
        icon: Icons.card_giftcard_rounded,
        page: EmployeeRecognitionsPage(),
      ),
      NavDestination(
        title: 'Points',
        icon: Icons.account_balance_wallet_rounded,
        page: PointsPage(userRole: r),
      ),
      const NavDestination(
        title: 'Rewards',
        icon: Icons.shopping_bag_rounded,
        page: EmployeeRewardsPage(),
      ),
      const NavDestination(
        title: 'Nominations',
        icon: Icons.emoji_events_rounded,
        page: EmployeeNominationsPage(),
      ),
    ];
  }
}
