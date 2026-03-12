import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../injection_container.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_event.dart';
import '../bloc/recognitions_state.dart';
import '../widgets/badge_summary_panel.dart';
import '../widgets/compact_send_panel.dart';
import '../widgets/recognition_feed_list.dart';

class EmployeeRecognitionsPage extends StatelessWidget {
  const EmployeeRecognitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecognitionsBloc>()
        ..add(GetBadgesRequested())
        ..add(GetAppreciationStatsRequested())
        ..add(GetRecognitionFeedRequested())
        ..add(GetUsersRequested()),
      child: BlocListener<RecognitionsBloc, RecognitionsState>(
        listener: (context, state) {
          if (state.status == RecognitionStatus.success &&
              state.lastSentRecognition != null) {
            AppSnackbar.success(context, 'Recognition sent successfully!');
          } else if (state.status == RecognitionStatus.failure) {
            AppSnackbar.error(
                context, state.errorMessage ?? 'Failed to send recognition');
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.pagePadding(context)),
            child: BlocBuilder<RecognitionsBloc, RecognitionsState>(
              builder: (context, state) {
                // Full-page loading only on first load
                if (state.status == RecognitionStatus.loading &&
                    state.badges.isEmpty &&
                    state.stats == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == RecognitionStatus.failure &&
                    state.badges.isEmpty &&
                    state.stats == null) {
                  return EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load recognitions',
                    message: state.errorMessage,
                    onRetry: () => context
                        .read<RecognitionsBloc>()
                        .add(GetBadgesRequested()),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 768;

                    // ── Left column ───────────────────────────────────
                    // 1. Compact send panel (collapsed — badges hidden)
                    // 2. Org-wide recognition feed
                    final leftColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompactSendPanel(
                          stats: state.stats,
                          badges: state.badges,
                          users: state.users,
                        ),
                        const SizedBox(height: 24),
                        _OrgFeedPanel(
                          feed: state.feed,
                          isLoading:
                              state.status == RecognitionStatus.loading &&
                                  state.feed.isEmpty,
                          height: isWide
                              ? MediaQuery.of(context).size.height * 0.56
                              : 400,
                        ),
                      ],
                    );

                    // ── Right column ──────────────────────────────────
                    // 1. Badge grid with per-badge count overlays
                    // 2. Personal received recognitions feed (filterable)
                    final rightColumn = state.stats != null
                        ? BadgeSummaryPanel(stats: state.stats!)
                        : _loadingCard(context);

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: send + org feed  (35 %)
                          Expanded(flex: 50, child: leftColumn),
                          const SizedBox(width: 24),
                          // Right: badge grid + received feed  (50 %)
                          Expanded(flex: 50, child: rightColumn),
                        ],
                      );
                    }

                    // Narrow / mobile – stack vertically
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Send panel on top
                        CompactSendPanel(
                          stats: state.stats,
                          badges: state.badges,
                          users: state.users,
                        ),
                        const SizedBox(height: 24),
                        // Badge grid + received feed
                        if (state.stats != null)
                          BadgeSummaryPanel(stats: state.stats!),
                        const SizedBox(height: 24),
                        // Org feed at the bottom
                        _OrgFeedPanel(
                          feed: state.feed,
                          isLoading:
                              state.status == RecognitionStatus.loading &&
                                  state.feed.isEmpty,
                          height: 400,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Org-wide recognition feed panel
// ─────────────────────────────────────────────────────────────────────────────
class _OrgFeedPanel extends StatelessWidget {
  final List feed;
  final bool isLoading;
  final double height;

  const _OrgFeedPanel({
    required this.feed,
    required this.isLoading,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recognition Feed',
            style: AppTextStyles.sectionHeader(),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Latest appreciations across the organisation',
            style: AppTextStyles.body(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RecognitionFeedList(
                    feed: feed.cast(),
                  ),
          ),
        ],
      ),
    );
  }
}
