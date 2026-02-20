import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/appreciation_stats_entity.dart';

class AppreciationStats extends StatelessWidget {
  final AppreciationStatsEntity stats;

  const AppreciationStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appreciations Received',
              style: AppTextStyles.sectionHeader(),
            ),
            const SizedBox(height: 24),
            if (stats.receivedCount == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No appreciations yet',
                      style: AppTextStyles.sectionTitle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.badgeCounts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final badgeName = stats.badgeCounts.keys.elementAt(index);
                    final count = stats.badgeCounts.values.elementAt(index);
                    return _buildStatCard(context, badgeName, count);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String badgeName, int count) {
    final theme = Theme.of(context);
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _getBadgeIcon(badgeName),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  badgeName,
                  style: AppTextStyles.bodyLarge(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: AppTextStyles.display(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBadgeIcon(String badgeName) {
    final info = BadgeUtils.getDisplayInfo(badgeName);
    final color = info.effectiveIconColor;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(info.icon, color: color, size: 20),
    );
  }
}
