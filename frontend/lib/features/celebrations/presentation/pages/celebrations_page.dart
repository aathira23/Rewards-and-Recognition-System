import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/celebration_entity.dart';
import '../bloc/celebrations_bloc.dart';
import '../bloc/celebrations_event.dart';
import '../bloc/celebrations_state.dart';

class CelebrationsPage extends StatelessWidget {
  const CelebrationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CelebrationsBloc>()
        ..add(const GetUpcomingCelebrationsRequested())
        ..add(GetCelebrationHistoryRequested()),
      child: const _CelebrationsView(),
    );
  }
}

class _CelebrationsView extends StatelessWidget {
  const _CelebrationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<CelebrationsBloc, CelebrationsState>(
        builder: (context, state) {
          if (state.status == CelebrationsStatus.loading &&
              state.upcoming.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Celebrations',
                    style: AppTextStyles.pageTitle()),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upcoming
                    Expanded(
                      flex: 55,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.celebration_rounded,
                                  color: Colors.pink.shade400, size: 22),
                              const SizedBox(width: 8),
                              Text('Upcoming Celebrations',
                                  style: AppTextStyles.sectionTitle()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (state.upcoming.isEmpty)
                            _buildEmptyState(
                                'No upcoming celebrations', Icons.event_busy),
                          ...state.upcoming
                              .map((c) => _buildCelebrationCard(c, theme)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // History
                    Expanded(
                      flex: 45,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  color: Colors.blue.shade400, size: 22),
                              const SizedBox(width: 8),
                              Text('Recent Celebrations',
                                  style: AppTextStyles.sectionTitle()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (state.history.isEmpty)
                            _buildEmptyState(
                                'No celebration history', Icons.history),
                          ...state.history
                              .map((c) => _buildHistoryTile(c, theme)),
                        ],
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

  Widget _buildCelebrationCard(CelebrationEntity c, ThemeData theme) {
    final isBirthday = c.celebrationType.toUpperCase() == 'BIRTHDAY';
    final icon = isBirthday ? Icons.cake_rounded : Icons.work_rounded;
    final color = isBirthday ? Colors.pink.shade400 : Colors.teal.shade400;
    final label = isBirthday ? 'Birthday' : 'Work Anniversary';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.userName,
                    style: AppTextStyles.cardTitle()),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: AppTextStyles.captionBold(
                          color: color)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(c.celebrationDate,
                  style: AppTextStyles.small(color: Colors.grey.shade600)),
              if (c.pointsAwarded > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${c.pointsAwarded} pts',
                      style: AppTextStyles.smallBold(
                          color: Colors.green.shade600)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(CelebrationEntity c, ThemeData theme) {
    final isBirthday = c.celebrationType.toUpperCase() == 'BIRTHDAY';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isBirthday ? Icons.cake : Icons.work,
            size: 18,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(c.userName,
                style: AppTextStyles.bodyMedium()),
          ),
          Text('+${c.pointsAwarded}',
              style: AppTextStyles.smallBold(
                  color: Colors.green.shade600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
