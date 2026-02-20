import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/analytics_entity.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

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
  late String _activeScope;

  @override
  void initState() {
    super.initState();
    _activeScope = widget.scope;
  }

  void _refresh() {
    context
        .read<AnalyticsBloc>()
        .add(GetAnalyticsRequested(scope: _activeScope));
  }

  void _changeScope(String scope) {
    setState(() => _activeScope = scope);
    context.read<AnalyticsBloc>().add(GetAnalyticsRequested(scope: scope));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state.status == AnalyticsStatus.loading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(100),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state.status == AnalyticsStatus.failure) {
            return EmptyStateView(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load analytics',
              message: state.errorMessage,
              onRetry: _refresh,
            );
          }

          final data = state.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildMetricCards(theme, data),
                const SizedBox(height: 20),
                _buildTrendsSection(theme, data),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildLeaderboard(
                        theme: theme,
                        title: 'Top Recognizers',
                        subtitle: 'People who give the most recognition',
                        items: data?.topRecognizers ?? [],
                        emptyIcon: Icons.volunteer_activism_rounded,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildLeaderboard(
                        theme: theme,
                        title: 'Most Recognized',
                        subtitle: 'People who receive the most recognition',
                        items: data?.topRecognized ?? [],
                        emptyIcon: Icons.emoji_events_rounded,
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

  // ───────────────────────────────────────────────────────────────
  // HEADER
  // ───────────────────────────────────────────────────────────────
  Widget _buildHeader(ThemeData theme) {
    final scopeLabel = _activeScope == 'ORG'
        ? 'Organization'
        : _activeScope == 'DEPARTMENT'
            ? 'Department'
            : 'Team';

    return Row(
      children: [
        _ScopeChip(
          label: 'Organization',
          isActive: _activeScope == 'ORG',
          onTap: () => _changeScope('ORG'),
        ),
        const SizedBox(width: 8),
        _ScopeChip(
          label: 'Department',
          isActive: _activeScope == 'DEPARTMENT',
          onTap: () => _changeScope('DEPARTMENT'),
        ),
        const SizedBox(width: 8),
        _ScopeChip(
          label: 'Team',
          isActive: _activeScope == 'TEAM',
          onTap: () => _changeScope('TEAM'),
        ),
        const Spacer(),
        Text(
          scopeLabel,
          style: AppTextStyles.small(color: Colors.grey.shade400),
        ),
        const SizedBox(width: 12),
        _buildRefreshButton(theme),
      ],
    );
  }

  Widget _buildRefreshButton(ThemeData theme) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(Icons.refresh_rounded,
              size: 18, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // METRIC CARDS
  // ───────────────────────────────────────────────────────────────
  Widget _buildMetricCards(ThemeData theme, AnalyticsEntity? data) {
    return Row(
      children: [
        _MetricCard(
          label: 'Recognitions',
          value: _fmt(data?.totalRecognitions ?? 0),
          icon: Icons.workspace_premium_rounded,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 16),
        _MetricCard(
          label: 'Points Distributed',
          value: _fmt(data?.totalPointsDistributed ?? 0),
          icon: Icons.toll_rounded,
          color: const Color(0xFF0D9488),
        ),
        const SizedBox(width: 16),
        _MetricCard(
          label: 'Engagement',
          value: '${(data?.engagementRate ?? 0).toStringAsFixed(0)}%',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 16),
        _MetricCard(
          label: 'Active Users',
          value: _fmt(data?.userCount ?? 0),
          icon: Icons.people_outline_rounded,
          color: const Color(0xFFD97706),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────
  // TRENDS CHART
  // ───────────────────────────────────────────────────────────────
  Widget _buildTrendsSection(ThemeData theme, AnalyticsEntity? data) {
    final trends = data?.trends ?? [];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recognition Activity', style: AppTextStyles.cardTitle()),
              const Spacer(),
              if (trends.isNotEmpty)
                Text('${trends.length} days',
                    style: AppTextStyles.caption(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 20),
          if (trends.isEmpty)
            const EmptyStateView(
              icon: Icons.insights_rounded,
              title: 'No activity data yet',
              padding: 24,
            )
          else
            _TrendChart(trends: trends, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // LEADERBOARDS
  // ───────────────────────────────────────────────────────────────
  Widget _buildLeaderboard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required IconData emptyIcon,
  }) {
    final primary = theme.colorScheme.primary;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle()),
          const SizedBox(height: 2),
          Text(subtitle,
              style: AppTextStyles.caption(color: Colors.grey.shade400)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            EmptyStateView(
              icon: emptyIcon,
              title: 'No data available',
              padding: 24,
            )
          else
            ...items.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final item = entry.value;
              final name = item['name']?.toString() ?? 'Unknown';
              final count = (item['count'] as num?)?.toInt() ?? 0;
              final maxCount = (items.first['count'] as num?)?.toInt() ?? 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3 ? primary : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: maxCount > 0 ? count / maxCount : 0,
                              minHeight: 3,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary.withOpacity(0.25 +
                                    (count / math.max(maxCount, 1)) * 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────────────

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble()
          ? '${k.round()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

// ═════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: child,
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ScopeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: isActive ? primary : Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? primary : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 8),
                  Text(value, style: AppTextStyles.headline2()),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  final Color color;
  const _TrendChart({required this.trends, required this.color});

  @override
  Widget build(BuildContext context) {
    final display =
        trends.length > 21 ? trends.sublist(trends.length - 21) : trends;

    return SizedBox(
      height: 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 160),
            painter: _TrendPainter(data: display, color: color),
          );
        },
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color color;
  _TrendPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final counts =
        data.map((d) => ((d['count'] as num?) ?? 0).toDouble()).toList();
    final maxVal = counts.reduce(math.max).clamp(1.0, double.infinity);

    const chartLeft = 28.0;
    const chartBottom = 22.0;
    final chartWidth = size.width - chartLeft - 8;
    final chartHeight = size.height - chartBottom - 4;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;

    final gridLabelStyle = TextStyle(
      fontSize: 9,
      color: Colors.grey.shade400,
    );

    for (int i = 0; i <= 4; i++) {
      final y = 4 + chartHeight - (chartHeight * i / 4);
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(size.width - 8, y),
        gridPaint,
      );

      final label = '${(maxVal * i / 4).round()}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: gridLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 6, y - tp.height / 2));
    }

    // Bars
    final barWidth = chartWidth / data.length;
    final barPadding = barWidth * 0.25;

    for (int i = 0; i < counts.length; i++) {
      final val = counts[i];
      final barH = (val / maxVal) * chartHeight;
      final x = chartLeft + i * barWidth + barPadding;
      final w = barWidth - barPadding * 2;
      final y = 4 + chartHeight - barH;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, barH),
        const Radius.circular(3),
      );

      final barPaint = Paint()
        ..color = color.withValues(alpha: 0.55 + (val / maxVal) * 0.4);
      canvas.drawRRect(barRect, barPaint);

      // X-axis labels
      final showLabel = data.length <= 10 ||
          i % (data.length ~/ 7 + 1) == 0 ||
          i == data.length - 1;

      if (showLabel) {
        final dateStr = data[i]['date']?.toString() ?? '';
        String label = '';
        if (dateStr.length >= 10) {
          try {
            final dt = DateTime.parse(dateStr);
            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            label = data.length <= 7
                ? days[dt.weekday - 1]
                : '${dt.day}/${dt.month}';
          } catch (_) {
            label = dateStr.length >= 5 ? dateStr.substring(5) : dateStr;
          }
        }

        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(x + w / 2 - tp.width / 2, size.height - chartBottom + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      data != old.data || color != old.color;
}
