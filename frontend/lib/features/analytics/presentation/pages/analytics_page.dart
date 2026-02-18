import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

class AnalyticsPage extends StatelessWidget {
  final String userRole;
  const AnalyticsPage({super.key, required this.userRole});

  String get _scope {
    switch (userRole.toUpperCase()) {
      case 'HR':
        return 'ORG';
      case 'DEPT_HEAD':
        return 'DEPARTMENT';
      default:
        return 'TEAM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<AnalyticsBloc>()..add(GetAnalyticsRequested(scope: _scope)),
      child: _AnalyticsView(userRole: userRole, scope: _scope),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  final String userRole;
  final String scope;
  const _AnalyticsView({required this.userRole, required this.scope});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state.status == AnalyticsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == AnalyticsStatus.failure) {
            return Center(
                child: Text('Error: ${state.errorMessage}',
                    style: TextStyle(color: Colors.red.shade700)));
          }

          final data = state.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analytics Dashboard',
                            style: GoogleFonts.outfit(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Scope: $scope',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        context
                            .read<AnalyticsBloc>()
                            .add(GetAnalyticsRequested(scope: scope));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // KPI Cards Row
                Row(
                  children: [
                    _buildKpiCard(
                      'Total Recognitions',
                      '${data?.totalRecognitions ?? 0}',
                      Icons.card_giftcard_rounded,
                      Colors.blue,
                      theme,
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      'Points Awarded',
                      '${data?.totalPointsAwarded ?? 0}',
                      Icons.stars_rounded,
                      Colors.amber.shade700,
                      theme,
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      'Active Users',
                      '${data?.activeUsers ?? 0}',
                      Icons.people_rounded,
                      Colors.green,
                      theme,
                    ),
                    const SizedBox(width: 16),
                    _buildKpiCard(
                      'Budget Utilization',
                      '${(data?.budgetUtilization ?? 0).toStringAsFixed(1)}%',
                      Icons.pie_chart_rounded,
                      Colors.purple,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Content row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Performers
                    Expanded(
                      flex: 55,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up_rounded,
                                    color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Top Performers',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (data == null || data.topPerformers.isEmpty) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text('No data available yet',
                                      style: TextStyle(
                                          color: Colors.grey.shade500)),
                                ),
                              ),
                            ] else
                              ...data.topPerformers
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final performer = entry.value;
                                return _buildPerformerRow(
                                    index + 1, performer, theme);
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Department Breakdown
                    Expanded(
                      flex: 45,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.business_rounded,
                                    color: Colors.teal, size: 20),
                                const SizedBox(width: 8),
                                Text('Department Breakdown',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (data == null ||
                                data.departmentBreakdown.isEmpty) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text('No data available yet',
                                      style: TextStyle(
                                          color: Colors.grey.shade500)),
                                ),
                              ),
                            ] else
                              ...data.departmentBreakdown.map((dept) {
                                return _buildDeptRow(dept, theme);
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(
      String label, String value, IconData icon, Color color, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerRow(
      int rank, Map<String, dynamic> performer, ThemeData theme) {
    final name = performer['name']?.toString() ?? 'Unknown';
    final score = performer['score']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rank <= 3
            ? Colors.amber.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: rank <= 3
                ? Icon(Icons.emoji_events,
                    size: 18,
                    color: rank == 1
                        ? Colors.amber
                        : rank == 2
                            ? Colors.grey.shade400
                            : Colors.brown.shade300)
                : Text('#$rank',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(name[0].toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Text('$score pts',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDeptRow(Map<String, dynamic> dept, ThemeData theme) {
    final name =
        dept['department']?.toString() ?? dept['name']?.toString() ?? 'Unknown';
    final count =
        dept['recognitions']?.toString() ?? dept['count']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 18, color: Colors.teal.shade300),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Text(count,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
