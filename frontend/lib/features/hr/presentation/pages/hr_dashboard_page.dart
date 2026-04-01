import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import 'package:rr_frontend/core/utils/responsive.dart';
import 'package:rr_frontend/injection_container.dart';
import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import 'package:rr_frontend/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:rr_frontend/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:rr_frontend/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_bloc.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_event.dart' as rec;
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_state.dart';
import 'package:rr_frontend/features/recognitions/presentation/widgets/recognition_feed_list.dart';

class HrDashboardPage extends StatelessWidget {
  final String userRole;
  const HrDashboardPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AnalyticsBloc>()
            ..add(const GetAnalyticsRequested(scope: 'ORG')),
        ),
        BlocProvider(
          create: (context) => sl<RecognitionsBloc>()
            ..add(rec.GetRecognitionFeedRequested()),
        ),
      ],
      child: const _HrDashboardView(),
    );
  }
}

class _HrDashboardView extends StatelessWidget {
  const _HrDashboardView();

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildSummaryBanner(context),
            const SizedBox(height: 40),
            _buildModulesSection(context),
            const SizedBox(height: 40),
            _buildRecentFeed(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rewards & Recognition',
          style: AppTextStyles.displayLarge(color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Celebrate, Earn, and Redeem!',
          style: AppTextStyles.bodyLarge(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSummaryBanner(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        final data = state.data;
        final totalRec = data?.totalRecognitions ?? 0;
        final totalPts = data?.totalPointsDistributed ?? 0;

        const bannerColor = Color(0xFF2D2A70);

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Recognitions',
                  _fmt(totalRec),
                  Icons.workspace_premium_rounded,
                  const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatCard(
                  'Points Distributed',
                  _fmt(totalPts),
                  Icons.toll_rounded,
                  const Color(0xFF0284C7),
                ),
              ),
              const Spacer(),
              // Placeholder for visual balance
              const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.displayMedium(color: Colors.black87)),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.caption(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Main Modules', style: AppTextStyles.sectionHeader()),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          int columns = 1;
          if (availableWidth > 1200) {
            columns = 5;
          } else if (availableWidth > 900) {
            columns = 3;
          } else if (availableWidth > 600) {
            columns = 2;
          }

          const double spacing = 16;
          final double cardWidth = (availableWidth - (columns - 1) * spacing) / columns;

          final List<Widget> cards = [
            _buildDynamicModuleCard(
              context,
              'Analytics',
              'Deep dive into company performance.',
              Icons.analytics_rounded,
              const Color(0xFFF0FDFA),
              const Color(0xFF0D9488),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Analytics'),
            ),
            _buildDynamicModuleCard(
              context,
              'Reports',
              'Generate & export data insights.',
              Icons.summarize_rounded,
              const Color(0xFFFDF4FF),
              const Color(0xFFC026D3),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Reports'),
            ),
            _buildDynamicModuleCard(
              context,
              'Configuration',
              'Manage awards, badges & rules.',
              Icons.tune_rounded,
              const Color(0xFFF0F9FF),
              const Color(0xFF0284C7),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Configuration'),
            ),
            _buildDynamicModuleCard(
              context,
              'Approvals',
              'Review and action pending items.',
              Icons.task_alt_rounded,
              const Color(0xFFFFF7ED),
              const Color(0xFFEA580C),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Approvals & Allocation'),
            ),
            _buildDynamicModuleCard(
              context,
              'Leaderboard',
              'Explore top contributors org-wide.',
              Icons.military_tech_outlined,
              const Color(0xFFF5F3FF),
              const Color(0xFF7C3AED),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Leaderboard'),
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards,
          );
        }),
      ],
    );
  }

  Widget _buildDynamicModuleCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color bgColor,
      Color iconColor,
      double width,
      {VoidCallback? onTap}) {
    return SizedBox(
      width: width,
      child: _HoverableModuleCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        bgColor: bgColor,
        iconColor: iconColor,
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentFeed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Feed', style: AppTextStyles.sectionHeader()),
        const SizedBox(height: 24),
        BlocBuilder<RecognitionsBloc, RecognitionsState>(
          builder: (context, state) {
            if (state.status == RecognitionStatus.loading && state.feed.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.feed.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Center(child: Text('No recent activity found', style: AppTextStyles.body(color: Colors.grey[500]))),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 600),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: RecognitionFeedList(
                feed: state.feed,
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
              ),
            );
          },
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final k = n / 1000;
      return k == k.roundToDouble() ? '${k.round()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _HoverableModuleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _HoverableModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  State<_HoverableModuleCard> createState() => _HoverableModuleCardState();
}

class _HoverableModuleCardState extends State<_HoverableModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.02),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: AppTextStyles.bodyBold(color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: AppTextStyles.small(color: Colors.grey[500]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
