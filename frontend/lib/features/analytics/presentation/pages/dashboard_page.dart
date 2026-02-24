import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
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
  final String userName;
  final String userRole;

  const DashboardPage({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final destinations = _buildDestinations(userRole);

    return MainLayout(
      userName: userName,
      userRole: _displayRole(userRole),
      destinations: destinations,
      onLogout: () {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      },
    );
  }

  /// Returns a human-readable role label for the sidebar.
  String _displayRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
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

    if (r == 'HR' || r == 'ADMIN') {
      return [
        NavDestination(
          title: 'Analytics',
          subtitle: 'Organisation-wide performance insights',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
        const NavDestination(
          title: 'Reports',
          subtitle: 'Generate, filter and export detailed reports',
          icon: Icons.summarize_rounded,
          page: ReportsPage(),
        ),
        const NavDestination(
          title: 'Configuration',
          subtitle: 'Manage awards, badges, catalog & point rules',
          icon: Icons.tune_rounded,
          page: HrConfigPage(),
        ),
        const NavDestination(
          title: 'Approvals & Allocation',
          subtitle: 'Review nominations, conversions & allocate budgets',
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
          heading: 'Recognitions Center',
          subtitle: 'Appreciate and celebrate your colleagues',
          icon: Icons.card_giftcard_rounded,
          page: EmployeeRecognitionsPage(),
        ),
        NavDestination(
          title: 'Points',
          heading: 'Points Overview',
          subtitle: 'Track your earnings and influence',
          icon: Icons.account_balance_wallet_rounded,
          page: PointsPage(userRole: r),
        ),
        const NavDestination(
          title: 'Rewards',
          heading: 'Rewards Store',
          subtitle: 'Redeem your hard-earned points',
          icon: Icons.shopping_bag_rounded,
          page: EmployeeRewardsPage(),
        ),
        const NavDestination(
          title: 'Approvals',
          heading: 'Nomination Approvals',
          subtitle: 'Review and action pending award nominations',
          icon: Icons.task_alt_rounded,
          page: ManagerApprovalsPage(),
        ),
        NavDestination(
          title: 'Analytics',
          subtitle: 'Performance insights for your team',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
      ];
    }

    // ── EMPLOYEE ──────────────────────────────────────────────────
    return [
      const NavDestination(
        title: 'Recognitions',
        heading: 'Recognitions Center',
        subtitle: 'Appreciate and celebrate your colleagues',
        icon: Icons.card_giftcard_rounded,
        page: EmployeeRecognitionsPage(),
      ),
      NavDestination(
        title: 'Points',
        heading: 'Points Overview',
        subtitle: 'Track your earnings and influence',
        icon: Icons.account_balance_wallet_rounded,
        page: PointsPage(userRole: r),
      ),
      const NavDestination(
        title: 'Rewards',
        heading: 'Rewards Store',
        subtitle: 'Redeem your hard-earned points',
        icon: Icons.shopping_bag_rounded,
        page: EmployeeRewardsPage(),
      ),
      const NavDestination(
        title: 'Nominations',
        subtitle: 'Nominate a colleague or check your award status',
        icon: Icons.emoji_events_rounded,
        page: EmployeeNominationsPage(),
      ),
    ];
  }
}
