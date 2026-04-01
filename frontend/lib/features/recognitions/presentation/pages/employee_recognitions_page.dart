import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../injection_container.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_event.dart';
import '../bloc/recognitions_state.dart';
import '../widgets/badge_summary_panel.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/presentation/widgets/main_layout.dart';
import '../../../../core/theme/app_text_styles.dart';

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recognition sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == RecognitionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'Failed to send recognition'),
                backgroundColor: Colors.red,
              ),
            );
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

                    if (isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page header
                          _buildPageHeader(context),
                          const SizedBox(height: 24),
                          // Two-column layout
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    if (state.stats != null)
                                      BadgesEarnedSummary(stats: state.stats!)
                                    else
                                      _loadingCard(context),
                                    const SizedBox(height: 24),
                                    SendEcardPanel(
                                      stats: state.stats,
                                      badges: state.badges,
                                      users: state.users,
                                    ),
                                    const SizedBox(height: 24),
                                    if (state.stats != null)
                                      EcardHistoryTable(stats: state.stats!),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right column
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    if (state.stats != null)
                                      MyEcardsPanel(stats: state.stats!)
                                    else
                                      _loadingCard(context),
                                    const SizedBox(height: 24),
                                    EcardFeedPanel(feed: state.feed),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Narrow / mobile — stack vertically
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 24),
                        if (state.stats != null)
                          BadgesEarnedSummary(stats: state.stats!),
                        const SizedBox(height: 24),
                        if (state.stats != null)
                          MyEcardsPanel(stats: state.stats!),
                        const SizedBox(height: 24),
                        SendEcardPanel(
                          stats: state.stats,
                          badges: state.badges,
                          users: state.users,
                        ),
                        const SizedBox(height: 24),
                        EcardFeedPanel(feed: state.feed),
                        const SizedBox(height: 24),
                        if (state.stats != null)
                          EcardHistoryTable(stats: state.stats!),
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

  Widget _buildPageHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String destination = 'Recognitions';
        if (authState is AuthAuthenticated) {
          final role = authState.auth.user?.role.toUpperCase();
          if (role == 'HR' || role == 'ADMIN') {
            destination = 'Dashboard';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () =>
                  MainLayout.of(context)?.selectTabByTitle(destination),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded,
                        size: 20, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text('Back to Dashboard',
                        style: AppTextStyles.bodyBold(color: Colors.black87)),
                  ],
                ),
              ),
            ),
            Text('eCards',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Send a quick thank-you and celebrate your teammates with personalized eCards.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        );
      },
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
