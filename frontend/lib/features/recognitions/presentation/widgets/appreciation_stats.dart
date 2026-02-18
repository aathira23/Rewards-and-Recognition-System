import 'package:flutter/material.dart';
import '../../domain/entities/appreciation_stats_entity.dart';

class AppreciationStats extends StatelessWidget {
  final AppreciationStatsEntity stats;

  const AppreciationStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appreciations Received',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String badgeName) {
    // Placeholder logic for badge icons matched from mockup
    IconData icon;
    Color color;

    switch (badgeName.toLowerCase()) {
      case 'you rock !!!':
        icon = Icons.thumb_up_alt_outlined;
        color = Colors.green;
        break;
      case 'out of box thinker !!!':
        icon = Icons.lightbulb_outline;
        color = Colors.purple;
        break;
      case 'bright spark !!!':
        icon = Icons.lightbulb_outline;
        color = Colors.pink;
        break;
      case 'great team player !!!':
        icon = Icons.groups_outlined;
        color = Colors.orange;
        break;
      default:
        icon = Icons.stars_outlined;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
