import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../injection_container.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';
import '../../domain/entities/analytics_entity.dart';

class AnalyticsPage extends StatelessWidget {
  final String userRole;
  const AnalyticsPage({super.key, required this.userRole});

  String get _scope {
    switch (userRole.toUpperCase()) {
      case 'HR':
      case 'ADMIN':
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

class _AnalyticsView extends StatefulWidget {
  final String userRole;
  final String scope;
  const _AnalyticsView({required this.userRole, required this.scope});

  @override
  State<_AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<_AnalyticsView> {
  String _timePeriod = 'Last 30 Days';
  String _department = 'All Departments';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Failed to load analytics',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(state.errorMessage ?? '',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<AnalyticsBloc>()
                        .add(GetAnalyticsRequested(scope: widget.scope)),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10)),
                  ),
                ],
              ),
            );
          }

          final data = state.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Filter Row ──
                _buildFilterRow(context),
                const SizedBox(height: 24),

                // ── KPI Cards ──
                _buildKpiCards(theme, data),
                const SizedBox(height: 24),

                // ── Charts Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 55,
                      child: _buildTrendsChart(theme, data),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 45,
                      child: _buildDepartmentActivity(theme, data),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Top Recognized Table ──
                _buildTopRecognizedTable(theme, data),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Filter Row ──────────────────────────────────────────────
  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        _FilterDropdown(
          value: _timePeriod,
          items: const [
            'Last 7 Days',
            'Last 30 Days',
            'Last 90 Days',
            'This Year'
          ],
          onChanged: (v) => setState(() => _timePeriod = v),
        ),
        const SizedBox(width: 12),
        _FilterDropdown(
          value: _department,
          items: const [
            'All Departments',
            'Engineering',
            'Sales & Marketing',
            'Customer Support',
            'Human Resources',
            'Finance'
          ],
          onChanged: (v) => setState(() => _department = v),
        ),
        const SizedBox(width: 12),
        _FilterDropdown(
          value:
              'Scope: ${widget.scope == 'ORG' ? 'Global' : widget.scope == 'DEPARTMENT' ? 'Department' : 'Team'}',
          items: const ['Scope: Global', 'Scope: Department', 'Scope: Team'],
          onChanged: (v) {
            final scope = v.contains('Global')
                ? 'ORG'
                : v.contains('Department')
                    ? 'DEPARTMENT'
                    : 'TEAM';
            context
                .read<AnalyticsBloc>()
                .add(GetAnalyticsRequested(scope: scope));
          },
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh',
          onPressed: () => context
              .read<AnalyticsBloc>()
              .add(GetAnalyticsRequested(scope: widget.scope)),
        ),
      ],
    );
  }

  // ─── KPI Cards ───────────────────────────────────────────────
  Widget _buildKpiCards(ThemeData theme, AnalyticsEntity? data) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total Recognitions',
            value: _formatNumber(data?.totalRecognitions ?? 0),
            borderColor: const Color(0xFF3B82F6),
            icon: Icons.card_giftcard_rounded,
            iconBg: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Points Issued',
            value: _formatNumber(data?.totalPointsDistributed ?? 0),
            borderColor: const Color(0xFF8B5CF6),
            icon: Icons.bar_chart_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Active Users',
            value: '${(data?.engagementRate ?? 0).toStringAsFixed(0)}%',
            borderColor: const Color(0xFF10B981),
            icon: Icons.groups_rounded,
            iconBg: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KpiCard(
            label: 'Wallet Utilization',
            value: '${data?.userCount ?? 0}',
            borderColor: const Color(0xFFF59E0B),
            icon: Icons.attach_money_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  // ─── Recognition Trends Chart ────────────────────────────────
  Widget _buildTrendsChart(ThemeData theme, AnalyticsEntity? data) {
    final trends = data?.trends ?? [];
    // Group trends by day-of-week for display like the mockup
    final display =
        trends.length > 7 ? trends.sublist(trends.length - 7) : trends;

    final maxCount = display
        .map((t) => (t['count'] as num?) ?? 0)
        .fold<num>(1, (a, b) => a > b ? a : b);

    return Container(
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
              Text('Recognition Trends',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 24),
          if (display.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('No trend data yet',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y-axis labels
                  SizedBox(
                    width: 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$maxCount',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                        Text('${(maxCount * 0.75).round()}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                        Text('${(maxCount * 0.50).round()}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                        Text('${(maxCount * 0.25).round()}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                        Text('0',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: display.asMap().entries.map((entry) {
                        final t = entry.value;
                        final count = ((t['count'] as num?) ?? 0).toDouble();
                        final frac = maxCount > 0 ? count / maxCount : 0.0;
                        final date = t['date']?.toString() ?? '';
                        // Get day label
                        String dayLabel = '';
                        if (date.length >= 10) {
                          try {
                            final dt = DateTime.parse(date);
                            const days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ];
                            dayLabel = days[dt.weekday - 1];
                          } catch (_) {
                            dayLabel = date.substring(8);
                          }
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    width: double.infinity,
                                    height: (frac * 160).clamp(4.0, 160.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1)
                                          .withValues(alpha: 0.5 + frac * 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(dayLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Department Activity Panel ───────────────────────────────
  Widget _buildDepartmentActivity(ThemeData theme, AnalyticsEntity? data) {
    // Use top_recognizers + top_recognized to approximate department data
    // Since backend doesn't have a dedicated dept endpoint, we show top recognizers as dept proxies
    final recognizers = data?.topRecognizers ?? [];
    final recognized = data?.topRecognized ?? [];

    // Combine both lists for a departmental-style view
    final Map<String, int> deptMap = {};
    for (final r in [...recognizers, ...recognized]) {
      final name = r['name']?.toString() ?? 'Unknown';
      final count = (r['count'] as num?)?.toInt() ?? 0;
      deptMap[name] = (deptMap[name] ?? 0) + count;
    }
    final deptEntries = deptMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal =
        deptEntries.isNotEmpty ? deptEntries.first.value.toDouble() : 1.0;

    return Container(
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
              Text('Department Activity',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 20),
          if (deptEntries.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_rounded,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('No department data yet',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            ...deptEntries.take(5).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${e.value} recs',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value / maxVal,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6)),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ─── Top Recognized Employees Table ──────────────────────────
  Widget _buildTopRecognizedTable(ThemeData theme, AnalyticsEntity? data) {
    final recognized = data?.topRecognized ?? [];

    return Container(
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
              Text('Top Recognized Employees',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text('View All',
                    style: TextStyle(
                        fontSize: 13, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('EMPLOYEE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('RECOGNITIONS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 2,
                    child: Text('POINTS RECEIVED',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                Expanded(
                    flex: 1,
                    child: Text('TREND',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.grey))),
                SizedBox(width: 32),
              ],
            ),
          ),
          if (recognized.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No data yet',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ),
            )
          else
            ...recognized.asMap().entries.map((entry) {
              final item = entry.value;
              final name = item['name']?.toString() ?? 'Unknown';
              final count = (item['count'] as num?)?.toInt() ?? 0;
              // Simulate points (count * avg points per recognition)
              final points = count * 100;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text('$count',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatNumber(points),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${(count > 0 ? (count % 20) + 1 : 0)}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.visibility_outlined,
                        size: 18, color: Colors.grey.shade400),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)
      return '${(n / 1000).toStringAsFixed(0)},${(n % 1000).toString().padLeft(3, '0')}';
    return '$n';
  }
}

// ── KPI Card Widget ───────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.borderColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Colored left accent
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Filter Dropdown Widget ───────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: Colors.grey.shade500),
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
