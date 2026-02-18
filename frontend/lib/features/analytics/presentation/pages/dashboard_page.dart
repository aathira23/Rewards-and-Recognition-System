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
import 'package:rr_frontend/features/analytics/presentation/pages/analytics_page.dart';
import 'package:rr_frontend/features/budgets/presentation/pages/budgets_page.dart';
import 'package:rr_frontend/features/profile/presentation/pages/user_management_page.dart';
import 'package:rr_frontend/features/departments/presentation/pages/department_management_page.dart';
import 'package:rr_frontend/features/config/presentation/pages/system_config_page.dart';
import 'package:rr_frontend/features/points/presentation/pages/conversions_management_page.dart';

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
  /// EMPLOYEE  → Recognitions, Points, Rewards, Approvals
  /// MANAGER   → Same as Employee + Budgets + Analytics (TEAM)
  /// DEPT_HEAD → Same as Manager + Analytics (DEPARTMENT)
  /// HR        → Analytics (ORG), User Mgmt, Departments, Budget Allocation,
  ///             Awards & Approvals, Conversions, Recognitions, Rewards, System Config
  ///
  /// Celebrations surface via the notification bell inbox (celebration-type notifications).
  List<NavDestination> _buildDestinations(String role) {
    final r = role.toUpperCase();

    if (r == 'HR') {
      return [
        NavDestination(
          title: 'Analytics',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
        const NavDestination(
          title: 'User Management',
          icon: Icons.people_alt_rounded,
          page: UserManagementPage(),
        ),
        const NavDestination(
          title: 'Departments',
          icon: Icons.business_rounded,
          page: DepartmentManagementPage(),
        ),
        NavDestination(
          title: 'Budget Allocation',
          icon: Icons.account_balance_wallet_rounded,
          page: BudgetsPage(userRole: r),
        ),
        const NavDestination(
          title: 'Awards & Approvals',
          icon: Icons.emoji_events_rounded,
          page: EmployeeApprovalsPage(),
        ),
        const NavDestination(
          title: 'Conversions',
          icon: Icons.swap_horiz_rounded,
          page: ConversionsManagementPage(),
        ),
        const NavDestination(
          title: 'Recognitions',
          icon: Icons.card_giftcard_rounded,
          page: EmployeeRecognitionsPage(),
        ),
        const NavDestination(
          title: 'Rewards Catalog',
          icon: Icons.shopping_bag_rounded,
          page: EmployeeRewardsPage(),
        ),
        const NavDestination(
          title: 'System Config',
          icon: Icons.settings_rounded,
          page: SystemConfigPage(),
        ),
      ];
    }

    // --- EMPLOYEE / MANAGER / DEPT_HEAD common destinations ---
    final destinations = <NavDestination>[
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
        icon: Icons.rule_rounded,
        page: EmployeeApprovalsPage(),
      ),
    ];

    // MANAGER & DEPT_HEAD get Analytics (budget is now inside the Points wallet toggle)
    if (r == 'MANAGER' || r == 'DEPT_HEAD') {
      destinations.add(
        NavDestination(
          title: 'Analytics',
          icon: Icons.analytics_rounded,
          page: AnalyticsPage(userRole: r),
        ),
      );
    }

    return destinations;
  }
}
