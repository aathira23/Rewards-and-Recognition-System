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

import 'package:rr_frontend/features/points/presentation/bloc/points_bloc.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_event.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_state.dart';
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_bloc.dart';
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_event.dart' as nom;
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_state.dart';
import 'package:rr_frontend/features/nominations/presentation/widgets/nominate_employee_dialog.dart';
import 'package:rr_frontend/features/recognitions/presentation/widgets/compact_send_panel.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:rr_frontend/features/profile/domain/entities/user_entity.dart';
import 'package:rr_frontend/core/utils/leveling_utils.dart';

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
            ..add(rec.GetAppreciationStatsRequested())
            ..add(rec.GetRecognitionFeedRequested())
            ..add(rec.GetBadgesRequested())
            ..add(rec.GetUsersRequested()),
        ),
        BlocProvider(
          create: (context) => sl<PointsBloc>()..add(GetPointsSummaryRequested()),
        ),
        BlocProvider(
          create: (context) => sl<NominationsBloc>()
            ..add(nom.GetAwardTypesRequested())
            ..add(nom.GetNominationsRequested())
            ..add(nom.GetUsersRequested()),
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
            _buildSummaryRow(context),
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

  Widget _buildSummaryRow(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      if (isWide) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 25, child: _buildStatsBanner(context)),
              const SizedBox(width: 24),
              Expanded(flex: 10, child: _buildQuickActions(context)),
            ],
          ),
        );
      }

      return Column(
        children: [
          _buildStatsBanner(context),
          const SizedBox(height: 24),
          _buildQuickActions(context),
        ],
      );
    });
  }

  Widget _buildStatsBanner(BuildContext context) {
    return BlocBuilder<RecognitionsBloc, RecognitionsState>(
      builder: (context, recState) {
        return BlocBuilder<PointsBloc, PointsState>(
          builder: (context, ptsState) {
            return BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return BlocBuilder<NominationsBloc, NominationsState>(
                  builder: (context, nomState) {
                    final balance = ptsState.summary?.balance ?? 0;
                    final level = LevelingUtils.getLevel(balance);
                    final pointsToNext =
                        LevelingUtils.getPointsToNextLevel(balance);
                    final progress = LevelingUtils.getProgress(balance);

                    int currentUserId = -1;
                    if (authState is AuthAuthenticated) {
                      currentUserId = authState.auth.user?.id ?? -1;
                    }
                    final awardsCount = nomState.nominations
                        .where((n) =>
                            n.nomineeId == currentUserId &&
                            n.status.toLowerCase() == 'approved')
                        .length;

                    final ecardsCount = recState.stats?.receivedCount ?? 0;

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
                            child: _buildStatSmallCard(
                              'Awards Won',
                              awardsCount.toString(),
                              Icons.emoji_events_outlined,
                              const Color(0xFFFFF7ED),
                              const Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatSmallCard(
                              'eCards Earned',
                              ecardsCount.toString(),
                              Icons.favorite_outline_rounded,
                              const Color(0xFFFFF1F2),
                              const Color(0xFFE11D48),
                            ),
                          ),
                          const SizedBox(width: 48),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Color(0xFFFFCC00), size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CURRENT STANDING',
                                      style: AppTextStyles.captionStrong(
                                          color: Colors.white.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFCC00),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.shield_rounded,
                                            size: 52,
                                            color:
                                                Colors.black.withOpacity(0.12),
                                          ),
                                          Text(
                                            level.toString(),
                                            style: AppTextStyles.headline1(
                                                color: Colors.black
                                                    .withOpacity(0.55)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              balance.toString(),
                                              style: AppTextStyles.display(
                                                  color: Colors.white),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'pts',
                                              style: AppTextStyles.sectionTitle(
                                                  color: Colors.white
                                                      .withOpacity(0.85)),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Available Balance',
                                          style: AppTextStyles.bodyLarge(
                                              color: Colors.white
                                                  .withOpacity(0.7)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Level $level',
                                        style: AppTextStyles.smallBold(
                                            color: Colors.white)),
                                    if (pointsToNext != null)
                                      Text(
                                          '$pointsToNext pts to Level ${level + 1}',
                                          style: AppTextStyles.smallMedium(
                                              color: Colors.white
                                                  .withOpacity(0.9))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.12),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFFCC00)),
                                    minHeight: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatSmallCard(String label, String value, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      width: 140,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: iconColor.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 16),
              Text(value,
                  style: AppTextStyles.displayMedium(color: Colors.black87)),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.sectionHeader()),
          const SizedBox(height: 24),
          BlocBuilder<RecognitionsBloc, RecognitionsState>(
            builder: (context, state) {
              final bool canSend = state.status != RecognitionStatus.loading &&
                  state.badges.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !canSend
                      ? null
                      : () => showDialog(
                            context: context,
                            builder: (dialogCtx) => BadgePickerDialog(
                              badges: state.badges,
                              users: state.users,
                              outerContext: context,
                            ),
                          ),
                  icon: const Icon(Icons.favorite_outline_rounded, size: 18),
                  label: const Text('Send an eCard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2A70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              UserEntity? currentUser;
              if (authState is AuthAuthenticated) {
                currentUser = authState.auth.user;
              }

              return BlocBuilder<NominationsBloc, NominationsState>(
                builder: (context, state) {
                  final bool canNominate =
                      state.status != NominationsStatus.loading &&
                          state.awardTypes.isNotEmpty &&
                          currentUser != null;

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: !canNominate
                          ? null
                          : () => showDialog(
                                context: context,
                                builder: (_) => NominateEmployeeDialog(
                                  awardTypes: state.awardTypes,
                                  users: state.users,
                                  bloc: context.read<NominationsBloc>(),
                                  currentUser: currentUser!,
                                ),
                              ),
                      icon: const Icon(Icons.military_tech_outlined, size: 18),
                      label: const Text('Give an Award'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                },
              );
            },
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
          final List<Widget> cards = [
            _buildDynamicModuleCard(
              context,
              'Awards',
              'View nominations and award status.',
              Icons.emoji_events_rounded,
              const Color(0xFFFEF3C7),
              const Color(0xFFD97706),
              0, // Width will be calculated below
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Awards'),
            ),
            _buildDynamicModuleCard(
              context,
              'eCards',
              'Spread positivity & appreciate peers!',
              Icons.favorite_outline_rounded,
              const Color(0xFFFCE7F3),
              const Color(0xFFDB2777),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('eCards'),
            ),
            _buildDynamicModuleCard(
              context,
              'Rewards Store',
              'Redeem your hard-earned points',
              Icons.shopping_bag_rounded,
              const Color(0xFFECFDF5),
              const Color(0xFF059669),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Rewards'),
            ),
            _buildDynamicModuleCard(
              context,
              'Leaderboard',
              'Explore top contributors org-wide.',
              Icons.military_tech_outlined,
              const Color(0xFFF5F3FF),
              const Color(0xFF7C3AED),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Leaderboard'),
            ),
            _buildDynamicModuleCard(
              context,
              'Approvals and Allocation',
              'Review nominations and manage budgets',
              Icons.task_alt_rounded,
              const Color(0xFFFFF7ED),
              const Color(0xFFEA580C),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Approvals & Allocation'),
            ),
            _buildDynamicModuleCard(
              context,
              'Analytics',
              'Deep dive into company performance.',
              Icons.analytics_rounded,
              const Color(0xFFF0FDFA),
              const Color(0xFF0D9488),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Analytics'),
            ),
            _buildDynamicModuleCard(
              context,
              'Reports',
              'Generate & export data insights.',
              Icons.summarize_rounded,
              const Color(0xFFFDF4FF),
              const Color(0xFFC026D3),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Reports'),
            ),
            _buildDynamicModuleCard(
              context,
              'Configuration',
              'Manage awards, badges & rules.',
              Icons.tune_rounded,
              const Color(0xFFF0F9FF),
              const Color(0xFF0284C7),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('Configuration'),
            ),
            _buildDynamicModuleCard(
              context,
              'My Activity',
              'Track your activities and history.',
              Icons.history_rounded,
              const Color(0xFFF1F5F9),
              const Color(0xFF475569),
              0,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('My Activity'),
            ),
          ];

          if (availableWidth > 1200) {
            // 5, 4 Layout
            const double spacing = 16;
            final double cardWidth = (availableWidth - (5 - 1) * spacing) / 5;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: <Widget>[
                    ...cards.sublist(0, 4).map((c) => Padding(
                          padding: const EdgeInsets.only(right: spacing),
                          child: SizedBox(width: cardWidth, child: c),
                        )),
                    SizedBox(width: cardWidth, child: cards[4]),
                  ],
                ),
                const SizedBox(height: spacing),
                Row(
                  children: <Widget>[
                    ...cards.sublist(5, 8).map((c) => Padding(
                          padding: const EdgeInsets.only(right: spacing),
                          child: SizedBox(width: cardWidth, child: c),
                        )),
                    SizedBox(width: cardWidth, child: cards[8]),
                  ],
                ),
              ],
            );
          }

          columns = 1;
          if (availableWidth > 900) {
            columns = 3;
          } else if (availableWidth > 600) {
            columns = 2;
          }

          const double spacing = 16;
          final double cardWidth =
              (availableWidth - (columns - 1) * spacing) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards
                .map((c) => SizedBox(width: cardWidth, child: c))
                .toList(),
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
