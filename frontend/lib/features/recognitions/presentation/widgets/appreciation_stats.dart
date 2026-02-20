import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/appreciation_stats_entity.dart';

class AppreciationStats extends StatelessWidget {
  final AppreciationStatsEntity stats;

  const AppreciationStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appreciations Received',
          style: AppTextStyles.sectionHeader(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stats.badgeCounts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final badgeName = stats.badgeCounts.keys.elementAt(index);
              final count = stats.badgeCounts.values.elementAt(index);
              return _buildStatCard(context, badgeName, count);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String badgeName, int count) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
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
