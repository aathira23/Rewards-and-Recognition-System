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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Appreciations Received',
                    style: AppTextStyles.pageTitle(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stats.receivedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stats.receivedCount} Total',
                      style: AppTextStyles.bodyBold(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your achievements and recognitions from colleagues',
              style: AppTextStyles.body(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (stats.receivedCount == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No appreciations yet',
                      style: AppTextStyles.sectionTitle(
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great work starts with small steps. Keep going!',
                      style: AppTextStyles.small(color: Colors.grey[400]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: stats.badgeCounts.length,
                itemBuilder: (context, index) {
                  final badgeName = stats.badgeCounts.keys.elementAt(index);
                  final count = stats.badgeCounts.values.elementAt(index);
                  final iconUrl = stats.badgeIcons[badgeName];
                  return _ReceivedBadgeCard(
                    badgeName: badgeName,
                    count: count,
                    iconUrl: iconUrl,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedBadgeCard extends StatefulWidget {
  final String badgeName;
  final int count;
  final String? iconUrl;

  const _ReceivedBadgeCard({
    required this.badgeName,
    required this.count,
    this.iconUrl,
  });

  @override
  State<_ReceivedBadgeCard> createState() => _ReceivedBadgeCardState();
}

class _ReceivedBadgeCardState extends State<_ReceivedBadgeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final badgeInfo = BadgeUtils.getDisplayInfo(widget.badgeName);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovered
                  ? badgeInfo.color.withValues(alpha: 0.5)
                  : Colors.grey[200]!,
              width: _isHovered ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: badgeInfo.color.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            children: [
              // Icon section
              SizedBox(
                height: 60,
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: badgeInfo.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.iconUrl != null
                          ? Image.network(
                              widget.iconUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  badgeInfo.hasEmoji
                                      ? Text(badgeInfo.emoji!,
                                          style: AppTextStyles.emoji())
                                      : Icon(badgeInfo.icon,
                                          color: badgeInfo.color, size: 28),
                            )
                          : badgeInfo.hasEmoji
                              ? Text(badgeInfo.emoji!,
                                  style: AppTextStyles.emoji())
                              : Icon(badgeInfo.icon,
                                  color: badgeInfo.color, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name section
              SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    widget.badgeName,
                    style: AppTextStyles.cardTitle(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              // Count section
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.count}x',
                  style: AppTextStyles.bodyBold(
                    color: badgeInfo.color,
                  ).copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
