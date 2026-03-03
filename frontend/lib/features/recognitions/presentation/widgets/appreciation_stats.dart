import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../domain/entities/recognition_entity.dart';

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
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: (stats.receivedRecognitions ?? []).map((recognition) {
                  return _ReceivedHoverCard(recognition: recognition);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact badge card that expands on hover to reveal sender & message details.
class _ReceivedHoverCard extends StatefulWidget {
  final RecognitionEntity recognition;

  const _ReceivedHoverCard({required this.recognition});

  @override
  State<_ReceivedHoverCard> createState() => _ReceivedHoverCardState();
}

class _ReceivedHoverCardState extends State<_ReceivedHoverCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Compact (collapsed) dimensions
  static const double _compactWidth = 90;
  static const double _compactHeight = 100;

  // Expanded dimensions
  static const double _expandedHeight = 160;

  @override
  Widget build(BuildContext context) {
    final badgeName = widget.recognition.badge?.name ?? 'Badge';
    final badgeInfo = BadgeUtils.getDisplayInfo(badgeName);
    final senderName = widget.recognition.senderName ?? 'Someone';
    final message = widget.recognition.message;
    final date =
        DateFormat('MMM dd, yyyy').format(widget.recognition.createdAt);
    final iconUrl = widget.recognition.badge?.iconUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Clamp expanded width to available space
        final maxExpandedWidth = constraints.maxWidth.clamp(0.0, 280.0);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.hardEdge,
            width: _isHovered ? maxExpandedWidth : _compactWidth,
            height: _isHovered ? _expandedHeight : _compactHeight,
            padding: _isHovered ? EdgeInsets.zero : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? badgeInfo.color.withValues(alpha: 0.06)
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: _isHovered
                    ? badgeInfo.color.withValues(alpha: 0.4)
                    : Colors.grey[200]!,
                width: _isHovered ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(_isHovered ? 16 : 14),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: badgeInfo.color.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: _isHovered
                ? OverflowBox(
                    alignment: Alignment.topLeft,
                    maxWidth: 280,
                    maxHeight: _expandedHeight,
                    child: SizedBox(
                      width: 280,
                      height: _expandedHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildExpandedContent(
                          badgeInfo,
                          badgeName,
                          senderName,
                          message,
                          date,
                          iconUrl,
                        ),
                      ),
                    ),
                  )
                : _buildCompactContent(badgeInfo, badgeName, iconUrl),
          ),
        );
      },
    );
  }

  /// Collapsed state: just icon + badge name
  Widget _buildCompactContent(
      BadgeDisplayInfo badgeInfo, String badgeName, String? iconUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeInfo.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _buildBadgeIcon(badgeInfo, iconUrl, 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badgeName,
          style: AppTextStyles.small(color: Colors.grey[700]),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Expanded state: full details with sender, message, date
  Widget _buildExpandedContent(BadgeDisplayInfo badgeInfo, String badgeName,
      String senderName, String? message, String date, String? iconUrl) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badgeInfo.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _buildBadgeIcon(badgeInfo, iconUrl, 24),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badgeName,
                  style: AppTextStyles.cardTitle().copyWith(
                    color: badgeInfo.color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'From $senderName',
                        style: AppTextStyles.small(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"$message"',
                    style: AppTextStyles.small(
                      color: Colors.grey[700],
                    ).copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: AppTextStyles.small(color: Colors.grey[400]),
                    ),
                    if (widget.recognition.pointsAwarded > 0) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${widget.recognition.pointsAwarded} pts',
                          style: AppTextStyles.small(
                            color: badgeInfo.color,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(
      BadgeDisplayInfo badgeInfo, String? iconUrl, double size) {
    if (iconUrl != null) {
      return Image.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => badgeInfo.hasEmoji
            ? Text(badgeInfo.emoji!, style: AppTextStyles.emoji())
            : Icon(badgeInfo.icon, color: badgeInfo.color, size: size),
      );
    }
    return badgeInfo.hasEmoji
        ? Text(badgeInfo.emoji!, style: AppTextStyles.emoji())
        : Icon(badgeInfo.icon, color: badgeInfo.color, size: size);
  }
}
