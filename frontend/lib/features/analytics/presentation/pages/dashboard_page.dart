import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_event.dart';
import 'package:rr_frontend/core/presentation/models/nav_destination.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import 'package:rr_frontend/features/recognitions/presentation/pages/rr_dashboard_page.dart';
import 'package:rr_frontend/features/recognitions/presentation/pages/employee_recognitions_page.dart';

import 'package:rr_frontend/features/points/presentation/pages/my_activity_page.dart';
import 'package:rr_frontend/features/points/presentation/pages/leaderboard_page.dart';
import 'package:rr_frontend/features/catalog/presentation/pages/employee_rewards_page.dart';
import 'package:rr_frontend/features/nominations/presentation/pages/employee_nominations_page.dart';
import 'package:rr_frontend/features/nominations/presentation/pages/manager_approvals_page.dart';
import 'package:rr_frontend/features/analytics/presentation/pages/analytics_page.dart';
import 'package:rr_frontend/features/reports/presentation/pages/reports_page.dart';
import 'package:rr_frontend/features/hr/presentation/pages/hr_config_page.dart';
import 'package:rr_frontend/features/hr/presentation/pages/hr_approvals_page.dart';
import 'package:rr_frontend/features/hr/presentation/pages/hr_dashboard_page.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  final String userRole;

  const DashboardPage({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final List<NavDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _destinations = _buildDestinations(widget.userRole);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      userName: widget.userName,
      userRole: _displayRole(widget.userRole),
      destinations: _destinations,
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
          title: 'Dashboard',
          heading: 'Rewards & Recognition',
          subtitle: 'Overview of rewards and recognition',
          icon: Icons.dashboard_rounded,
          page: HrDashboardPage(userRole: r),
        ),
        const NavDestination(
          title: 'Awards',
          subtitle: 'View nominations and award status',
          icon: Icons.emoji_events_rounded,
          page: EmployeeNominationsPage(),
        ),
        const NavDestination(
          title: 'eCards',
          subtitle: 'Spread positivity & appreciate peers!',
          icon: Icons.favorite_outline_rounded,
          page: EmployeeRecognitionsPage(),
        ),
        const NavDestination(
          title: 'Rewards',
          subtitle: 'Redeem your hard-earned points',
          icon: Icons.shopping_bag_rounded,
          page: EmployeeRewardsPage(),
        ),
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
        NavDestination(
          title: 'My Activity',
          subtitle: 'Track your point earnings, redemptions, and conversions',
          icon: Icons.history_rounded,
          page: MyActivityPage(userRole: r),
        ),
        const NavDestination(
          title: 'Leaderboard',
          heading: 'Leaderboard',
          subtitle: 'Rise to the top & inspire others!',
          icon: Icons.military_tech_outlined,
          page: LeaderboardPage(),
          isHidden: true,
        ),
      ];
    }

    // ── MANAGER / DEPT_HEAD ───────────────────────────────────────
    if (r == 'MANAGER' || r == 'DEPT_HEAD') {
      return [
        NavDestination(
          title: 'Recognitions',
          heading: 'Rewards & Recognition',
          subtitle: 'Celebrate, Earn, and Redeem!',
          icon: Icons.card_giftcard_rounded,
          page: const RRDashboardPage(),
        ),
        const NavDestination(
          title: 'eCards',
          heading: 'eCards',
          subtitle: 'Spread positivity & appreciate peers!',
          icon: Icons.favorite_outline_rounded,
          page: EmployeeRecognitionsPage(),
        ),
        NavDestination(
          title: 'My Activity',
          heading: 'My Activity',
          subtitle: 'Track your point earnings, redemptions, and conversions',
          icon: Icons.history_rounded,
          page: MyActivityPage(userRole: r),
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
        const NavDestination(
          title: 'Leaderboard',
          heading: 'Leaderboard',
          subtitle: 'Rise to the top & inspire others!',
          icon: Icons.military_tech_outlined,
          page: LeaderboardPage(),
          isHidden: true,
        ),
      ];
    }

    // ── EMPLOYEE ──────────────────────────────────────────────────
    return [
      NavDestination(
        title: 'Recognitions',
        heading: 'Rewards & Recognition',
        subtitle: 'Celebrate, Earn, and Redeem!',
        icon: Icons.card_giftcard_rounded,
        page: const RRDashboardPage(),
      ),
      const NavDestination(
        title: 'eCards',
        heading: 'eCards',
        subtitle: 'Spread positivity & appreciate peers!',
        icon: Icons.favorite_outline_rounded,
        page: EmployeeRecognitionsPage(),
      ),
      NavDestination(
        title: 'My Activity',
        heading: 'Points Overview',
        subtitle: 'Track your earnings and influence',
        icon: Icons.history_rounded,
        page: MyActivityPage(userRole: r),
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
      const NavDestination(
        title: 'Leaderboard',
        heading: 'Leaderboard',
        subtitle: 'Rise to the top & inspire others!',
        icon: Icons.military_tech_outlined,
        page: LeaderboardPage(),
        isHidden: true,
      ),
    ];
  }
}
