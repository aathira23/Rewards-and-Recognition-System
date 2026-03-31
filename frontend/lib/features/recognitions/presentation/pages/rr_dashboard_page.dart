import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';

import 'package:rr_frontend/core/utils/responsive.dart';
import 'package:rr_frontend/core/utils/leveling_utils.dart';
import 'package:rr_frontend/injection_container.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_bloc.dart';
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_event.dart'
    as rec;
import 'package:rr_frontend/features/recognitions/presentation/bloc/recognitions_state.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_bloc.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_event.dart';
import 'package:rr_frontend/features/points/presentation/bloc/points_state.dart';
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_bloc.dart';
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_event.dart'
    as nom;
import 'package:rr_frontend/features/nominations/presentation/bloc/nominations_state.dart';
import 'package:rr_frontend/features/nominations/presentation/widgets/nominate_employee_dialog.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rr_frontend/features/auth/presentation/bloc/auth_state.dart';
import 'package:rr_frontend/features/profile/domain/entities/user_entity.dart';

import 'package:rr_frontend/core/presentation/widgets/main_layout.dart';
import 'package:rr_frontend/features/recognitions/presentation/widgets/recognition_feed_list.dart';
import 'package:rr_frontend/features/recognitions/presentation/widgets/compact_send_panel.dart';

class RRDashboardPage extends StatelessWidget {
  const RRDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<RecognitionsBloc>()
            ..add(rec.GetAppreciationStatsRequested())
            ..add(rec.GetRecognitionFeedRequested())
            ..add(rec.GetBadgesRequested())
            ..add(rec.GetUsersRequested()),
        ),
        BlocProvider(
          create: (context) =>
              sl<PointsBloc>()..add(GetPointsSummaryRequested()),
        ),
        BlocProvider(
          create: (context) => sl<NominationsBloc>()
            ..add(nom.GetAwardTypesRequested())
            ..add(nom.GetNominationsRequested())
            ..add(nom.GetUsersRequested()),
        ),
      ],
      child: const _RRDashboardView(),
    );
  }
}

class _RRDashboardView extends StatelessWidget {
  const _RRDashboardView();

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

                    // Awards Won = approved nominations where current user is the nominee
                    int currentUserId = -1;
                    if (authState is AuthAuthenticated) {
                      currentUserId = authState.auth.user?.id ?? -1;
                    }
                    final awardsCount = nomState.nominations
                        .where((n) =>
                            n.nomineeId == currentUserId &&
                            n.status.toLowerCase() == 'approved')
                        .length;

                    // eCards Earned = eCards received by the current user
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
          // Send an eCard
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
          // Give an Award
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
          final authState = context.read<AuthBloc>().state;
          bool isManager = false;
          if (authState is AuthAuthenticated) {
            final role = authState.auth.user?.role.toUpperCase();
            isManager = role == 'MANAGER' || role == 'DEPT_HEAD';
          }

          // ── Responsive column calculation ──
          final availableWidth = constraints.maxWidth;
          int columns = 1;
          if (availableWidth > 1200) {
            columns = isManager ? 6 : 5;
          } else if (availableWidth > 900) {
            columns = 3;
          } else if (availableWidth > 600) {
            columns = 2;
          }

          const double spacing = 16;
          final double cardWidth =
              (availableWidth - (columns - 1) * spacing) / columns;

          final List<Widget> cards = [
            _buildDynamicModuleCard(
              context,
              'Awards',
              'Celebrate outstanding achievements!',
              Icons.emoji_events_outlined,
              const Color(0xFFFFF7ED),
              const Color(0xFFEA580C),
              cardWidth,
              onTap: () {
                String targetTab = 'Nominations';
                if (authState is AuthAuthenticated) {
                  final role = authState.auth.user?.role.toUpperCase();
                  if (role == 'MANAGER' || role == 'DEPT_HEAD') {
                    targetTab = 'Approvals';
                  } else if (role == 'HR' || role == 'ADMIN') {
                    targetTab = 'Approvals & Allocation';
                  }
                }
                MainLayout.of(context)?.selectTabByTitle(targetTab);
              },
            ),
            _buildDynamicModuleCard(
              context,
              'eCards',
              'Spread positivity & appreciate peers!',
              Icons.favorite_outline_rounded,
              const Color(0xFFF0F9FF),
              const Color(0xFF0284C7),
              cardWidth,
              onTap: () => MainLayout.of(context)?.selectTabByTitle('eCards'),
            ),
            _buildDynamicModuleCard(
              context,
              'Leaderboard',
              'Rise to the top & inspire others!',
              Icons.military_tech_outlined,
              const Color(0xFFFDF4FF),
              const Color(0xFFC026D3),
              cardWidth,
              onTap: () {
                MainLayout.of(context)?.selectTabByTitle('Leaderboard');
              },
            ),
            _buildDynamicModuleCard(
              context,
              'Redeem Rewards',
              'Treat yourself to amazing gifts!',
              Icons.card_giftcard_rounded,
              const Color(0xFFF5F3FF),
              const Color(0xFF7C3AED),
              cardWidth,
              onTap: () {
                MainLayout.of(context)?.selectTabByTitle('Rewards');
              },
            ),
            _buildDynamicModuleCard(
              context,
              'My Activity',
              'Track your journey of excellence!',
              Icons.history_rounded,
              const Color(0xFFECFDF5),
              const Color(0xFF059669),
              cardWidth,
              onTap: () {
                MainLayout.of(context)?.selectTabByTitle('My Activity');
              },
            ),
          ];

          if (isManager) {
            cards.add(
              _buildDynamicModuleCard(
                context,
                'Team Analytics',
                'Insights into your team\'s performance!',
                Icons.analytics_rounded,
                const Color(0xFFF0FDFA), // Teal 50
                const Color(0xFF0D9488), // Teal 600
                cardWidth,
                onTap: () =>
                    MainLayout.of(context)?.selectTabByTitle('Analytics'),
              ),
            );
          }

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards,
          );
        }),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, String subtitle,
      IconData icon, Color bgColor, Color iconColor,
      {VoidCallback? onTap}) {
    return _HoverableModuleCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      bgColor: bgColor,
      iconColor: iconColor,
      onTap: onTap,
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
      child: _buildModuleCard(
          context, title, subtitle, icon, bgColor, iconColor,
          onTap: onTap),
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
            if (state.status == RecognitionStatus.loading &&
                state.feed.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.feed.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Center(
                    child: Text('No recent activity',
                        style: AppTextStyles.body(color: Colors.grey[500]))),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 500),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
