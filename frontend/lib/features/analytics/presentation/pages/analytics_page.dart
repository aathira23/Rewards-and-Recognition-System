import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_page_header.dart';
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

  void _refresh() => context
      .read<AnalyticsBloc>()
      .add(GetAnalyticsRequested(scope: _activeScope));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          final data = state.data;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(Responsive.pagePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page title ──────────────────────────────────
                  AppPageHeader(
                    action: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Refresh',
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (state.status == AnalyticsStatus.loading && data == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.status == AnalyticsStatus.failure)
                    EmptyStateView(
                      icon: Icons.cloud_off_rounded,
                      title: 'Unable to load analytics',
                      message: state.errorMessage,
                      onRetry: _refresh,
                    )
                  else ...[
                    // ── KPI Cards ──────────────────────────────
                    _buildMetricCards(theme, data),
                    const SizedBox(height: 20),

                    // ── Breakdown section ──────────────────────
                    if ((data?.breakdown ?? []).isNotEmpty) ...[
                      _buildBreakdownSection(theme, data!),
                      const SizedBox(height: 20),
                    ],

                    // ── Activity chart ─────────────────────────
                    _buildTrendsSection(theme, data),
                    const SizedBox(height: 20),

                    // ── Leaderboards ───────────────────────────
                    LayoutBuilder(builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth >= 768;
                      final left = _buildLeaderboard(
                        theme: theme,
                        title: 'Top Recognizers',
                        subtitle: 'People who give the most',
                        items: data?.topRecognizers ?? [],
                        emptyIcon: Icons.volunteer_activism_rounded,
                        color: primary,
                      );
                      final right = _buildLeaderboard(
                        theme: theme,
                        title: 'Most Recognized',
                        subtitle: 'People who receive the most',
                        items: data?.topRecognized ?? [],
                        emptyIcon: Icons.emoji_events_rounded,
                        color: const Color(0xFF0D9488),
                      );

                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: left),
                                const SizedBox(width: 20),
                                Expanded(child: right),
                              ],
                            )
                          : Column(children: [
                              left,
                              const SizedBox(height: 20),
                              right
                            ]);
                    }),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ── KPI metric cards ─────────────────────────────────────────────
  Widget _buildMetricCards(ThemeData theme, AnalyticsEntity? data) {
    final cards = [
      _KpiCard(
        label: 'Recognitions',
        value: _fmt(data?.totalRecognitions ?? 0),
        icon: Icons.workspace_premium_rounded,
        color: theme.colorScheme.primary,
        sub: 'Total in period',
      ),
      _KpiCard(
        label: 'Points Distributed',
        value: _fmt(data?.totalPointsDistributed ?? 0),
        icon: Icons.toll_rounded,
        color: const Color(0xFF0D9488),
        sub: 'Points awarded',
      ),
      _KpiCard(
        label: 'Engagement',
        value: '${(data?.engagementRate ?? 0).toStringAsFixed(0)}%',
        icon: Icons.show_chart_rounded,
        color: const Color(0xFF7C3AED),
        sub: 'Active participants',
      ),
      _KpiCard(
        label: 'People',
        value: _fmt(data?.userCount ?? 0),
        icon: Icons.people_outline_rounded,
        color: const Color(0xFFD97706),
        sub: 'In this scope',
      ),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth < 560;
      if (isNarrow) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1])
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3])
            ]),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 14),
          Expanded(child: cards[1]),
          const SizedBox(width: 14),
          Expanded(child: cards[2]),
          const SizedBox(width: 14),
          Expanded(child: cards[3]),
        ],
      );
    });
  }

  // ── Breakdown section ────────────────────────────────────────────
  Widget _buildBreakdownSection(ThemeData theme, AnalyticsEntity data) {
    final items = data.breakdown;
    final maxRec = items
        .map((e) => (e['recognition_count'] as num?)?.toInt() ?? 0)
        .fold<int>(1, math.max);

    final title =
        _activeScope == 'ORG' ? 'Department Breakdown' : 'Team Breakdown';
    final subtitle = _activeScope == 'ORG'
        ? 'Recognition activity by department'
        : 'Recognition activity by team';

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle()),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          AppTextStyles.caption(color: Colors.grey.shade400)),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length} ${_activeScope == 'ORG' ? 'depts' : 'teams'}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 640;
            if (isWide) {
              // 2-column grid
              final rows = <Widget>[];
              for (int i = 0; i < items.length; i += 2) {
                rows.add(Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _BreakdownRow(
                            item: items[i], maxRec: maxRec, theme: theme)),
                    const SizedBox(width: 24),
                    if (i + 1 < items.length)
                      Expanded(
                          child: _BreakdownRow(
                              item: items[i + 1], maxRec: maxRec, theme: theme))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ));
                if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
              }
              return Column(children: rows);
            }
            // Single column on narrow
            return Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BreakdownRow(
                            item: item, maxRec: maxRec, theme: theme),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // ── Recognition trends chart ─────────────────────────────────────
  Widget _buildTrendsSection(ThemeData theme, AnalyticsEntity? data) {
    final trends = data?.trends ?? [];
    final total =
        trends.fold<int>(0, (s, t) => s + ((t['count'] as num?)?.toInt() ?? 0));
    final avg = trends.isEmpty ? 0.0 : total / trends.length;
    final peak = trends.isEmpty
        ? null
        : trends.reduce((a, b) =>
            ((a['count'] as num?) ?? 0) >= ((b['count'] as num?) ?? 0) ? a : b);
    final peakLabel = peak == null
        ? null
        : () {
            final ds = peak['date']?.toString() ?? '';
            if (ds.length < 10) return ds;
            try {
              final dt = DateTime.parse(ds);
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return days[dt.weekday - 1];
            } catch (_) {
              return ds.substring(5);
            }
          }();

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recognition Activity',
                        style: AppTextStyles.cardTitle()),
                    const SizedBox(height: 2),
                    Text('Daily recognition count over time',
                        style: AppTextStyles.caption(
                            color: Colors.grey.shade400)),
                  ],
                ),
              ),
              const Spacer(),
              if (trends.isNotEmpty) ...[
                _TrendStat(
                    label: 'Total',
                    value: '$total',
                    color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                _TrendStat(
                    label: 'Avg/day',
                    value: avg.toStringAsFixed(1),
                    color: const Color(0xFF0D9488)),
                const SizedBox(width: 10),
                _TrendStat(
                    label: 'Peak',
                    value: peakLabel ?? '',
                    color: const Color(0xFFD97706)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (trends.isEmpty)
            const EmptyStateView(
              icon: Icons.insights_rounded,
              title: 'No activity data yet',
              padding: 32,
            )
          else
            _TrendChart(
                trends: trends, color: theme.colorScheme.primary, avg: avg),
        ],
      ),
    );
  }

  // ── Leaderboard ──────────────────────────────────────────────────
  Widget _buildLeaderboard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> items,
    required IconData emptyIcon,
    required Color color,
  }) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(emptyIcon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle()),
                  Text(subtitle,
                      style:
                          AppTextStyles.caption(color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
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

              final rankColors = [
                const Color(0xFFF59E0B),
                Colors.grey.shade400,
                const Color(0xFFB45309),
              ];
              final rankColor =
                  rank <= 3 ? rankColors[rank - 1] : Colors.grey.shade300;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? rankColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3 ? rankColor : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: maxCount > 0 ? count / maxCount : 0,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                color.withValues(
                                    alpha: 0.3 +
                                        (count / math.max(maxCount, 1)) * 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
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
// KPI CARD
// ═════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// BREAKDOWN ROW  (dept / team comparison bar)
// ═════════════════════════════════════════════════════════════════

class _BreakdownRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int maxRec;
  final ThemeData theme;
  const _BreakdownRow(
      {required this.item, required this.maxRec, required this.theme});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '—';
    final recCount = (item['recognition_count'] as num?)?.toInt() ?? 0;
    final points = (item['points'] as num?)?.toInt() ?? 0;
    final users = (item['user_count'] as num?)?.toInt() ?? 0;
    final engagement = (item['engagement'] as num?)?.toDouble() ?? 0.0;
    final ratio = maxRec > 0 ? recCount / maxRec : 0.0;

    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$recCount',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primary),
                  ),
                  Text(
                    'Recognitions',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.toDouble(),
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BreakdownStat(
                  icon: Icons.toll_rounded,
                  label: _fmtK(points),
                  color: const Color(0xFF0D9488)),
              const SizedBox(width: 14),
              _BreakdownStat(
                  icon: Icons.people_outline_rounded,
                  label: '$users',
                  color: const Color(0xFFD97706)),
              const SizedBox(width: 14),
              _BreakdownStat(
                  icon: Icons.show_chart_rounded,
                  label: '${engagement.toStringAsFixed(0)}%',
                  color: const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtK(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K pts';
    return '$n pts';
  }
}

class _BreakdownStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BreakdownStat(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// WHITE CARD WRAPPER
// ═════════════════════════════════════════════════════════════════

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TREND CHART  – smooth bezier area chart
// ═════════════════════════════════════════════════════════════════

class _TrendStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TrendStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trends;
  final Color color;
  final double avg;
  const _TrendChart(
      {required this.trends, required this.color, required this.avg});

  @override
  Widget build(BuildContext context) {
    final display =
        trends.length > 30 ? trends.sublist(trends.length - 30) : trends;
    return SizedBox(
      height: 200,
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(constraints.maxWidth, 200),
          painter: _TrendPainter(data: display, color: color, avg: avg),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color color;
  final double avg;
  _TrendPainter({required this.data, required this.color, required this.avg});

  String _dateLabel(String dateStr, int totalPoints) {
    if (dateStr.length < 10) return dateStr;
    try {
      final dt = DateTime.parse(dateStr);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return totalPoints <= 7 ? days[dt.weekday - 1] : '${dt.day}/${dt.month}';
    } catch (_) {
      return dateStr.length >= 5 ? dateStr.substring(5) : dateStr;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final counts =
        data.map((d) => ((d['count'] as num?) ?? 0).toDouble()).toList();
    final maxVal = counts.reduce(math.max).clamp(1.0, double.infinity);

    const leftPad = 34.0;
    const rightPad = 12.0;
    const topPad = 16.0;
    const bottomPad = 28.0;
    final cw = size.width - leftPad - rightPad;
    final ch = size.height - topPad - bottomPad;

    // ── grid lines ───────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 9.5, color: Colors.grey.shade400);

    final gridLines = maxVal.ceil().clamp(1, 5);
    for (int i = 0; i <= gridLines; i++) {
      final y = topPad + ch - (ch * i / gridLines);
      // dashed grid line
      const dashW = 6.0, gap = 4.0;
      double dx = leftPad;
      while (dx < size.width - rightPad) {
        canvas.drawLine(Offset(dx, y),
            Offset(math.min(dx + dashW, size.width - rightPad), y), gridPaint);
        dx += dashW + gap;
      }
      final labelVal = (maxVal * i / gridLines).round();
      final tp = TextPainter(
        text: TextSpan(text: '$labelVal', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // compute pixel positions for each data point
    final pts = <Offset>[];
    final step = cw / math.max(data.length - 1, 1);
    for (int i = 0; i < counts.length; i++) {
      final x = leftPad + i * step;
      final y = topPad + ch - (counts[i] / maxVal) * ch;
      pts.add(Offset(x, y));
    }

    // ── average reference line (dashed, amber) ────────────────────
    if (avg > 0) {
      final avgY = topPad + ch - (avg / maxVal) * ch;
      final avgPaint = Paint()
        ..color = const Color(0xFFD97706).withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      const dashLen = 8.0, dashGap = 5.0;
      double dx = leftPad;
      while (dx < size.width - rightPad) {
        canvas.drawLine(
            Offset(dx, avgY),
            Offset(math.min(dx + dashLen, size.width - rightPad), avgY),
            avgPaint);
        dx += dashLen + dashGap;
      }
      // avg label
      final tp = TextPainter(
        text: TextSpan(
            text: 'avg',
            style: const TextStyle(
                fontSize: 9,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(size.width - rightPad - tp.width - 2, avgY - tp.height - 2));
    }

    // ── filled gradient area ──────────────────────────────────────
    final areaPath = Path();
    areaPath.moveTo(pts.first.dx, topPad + ch);
    areaPath.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      areaPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    areaPath.lineTo(pts.last.dx, topPad + ch);
    areaPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, cw, ch));
    canvas.drawPath(areaPath, gradientPaint);

    // ── smooth line ───────────────────────────────────────────────
    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // ── data point dots + optional value labels ───────────────────
    final maxIdx = counts.indexOf(counts.reduce(math.max));
    for (int i = 0; i < pts.length; i++) {
      final isMax = i == maxIdx;
      final isEdge = i == 0 || i == pts.length - 1;
      final showDot = data.length <= 14 || isMax || isEdge;
      if (!showDot) continue;

      // outer ring
      canvas.drawCircle(
          pts[i],
          isMax ? 7.0 : 5.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pts[i],
          isMax ? 7.0 : 5.0,
          Paint()
            ..color = isMax ? color : color.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isMax ? 2.5 : 1.8);
      canvas.drawCircle(pts[i], isMax ? 3.5 : 2.5,
          Paint()..color = isMax ? color : color.withValues(alpha: 0.5));

      // value pill above peak
      if (isMax && counts[i] > 0) {
        final val = counts[i].toInt().toString();
        final tp = TextPainter(
          text: TextSpan(
              text: val,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          textDirection: TextDirection.ltr,
        )..layout();
        final pillW = tp.width + 10;
        final pillH = tp.height + 6;
        final pillX = pts[i].dx - pillW / 2;
        final pillY = pts[i].dy - 7 - pillH - 4;
        final pillRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(pillX, pillY, pillW, pillH),
            const Radius.circular(5));
        canvas.drawRRect(pillRect, Paint()..color = color);
        // small triangle pointer
        final tri = Path()
          ..moveTo(pts[i].dx - 5, pillY + pillH)
          ..lineTo(pts[i].dx + 5, pillY + pillH)
          ..lineTo(pts[i].dx, pillY + pillH + 5)
          ..close();
        canvas.drawPath(tri, Paint()..color = color);
        tp.paint(canvas, Offset(pillX + 5, pillY + 3));
      }
    }

    // ── x-axis labels ─────────────────────────────────────────────
    final showEvery = math.max(1, data.length ~/ 7);
    for (int i = 0; i < data.length; i++) {
      final isEdge = i == 0 || i == data.length - 1;
      if (!isEdge && i % showEvery != 0) continue;
      final lbl = _dateLabel(data[i]['date']?.toString() ?? '', data.length);
      final tp = TextPainter(
        text: TextSpan(text: lbl, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(pts[i].dx - tp.width / 2,
              topPad + ch + bottomPad - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      data != old.data || color != old.color || avg != old.avg;
}
