import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/appreciation_stats_entity.dart';
import '../../domain/entities/recognition_entity.dart';

/// Right-column panel for the recognitions page.
/// Top: badge grid showing every badge the user has received with a count bubble.
/// Bottom: scrollable received-recognitions feed (filterable by badge click).
class BadgeSummaryPanel extends StatefulWidget {
  final AppreciationStatsEntity stats;

  const BadgeSummaryPanel({super.key, required this.stats});

  @override
  State<BadgeSummaryPanel> createState() => _BadgeSummaryPanelState();
}

class _BadgeSummaryPanelState extends State<BadgeSummaryPanel> {
  /// When non-null, the feed shows only recognitions for this badge name.
  String? _filterBadge;

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final badgeCounts = stats.badgeCounts; // Map<String, int>
    final badgeIcons = stats.badgeIcons; // Map<String, String?>
    final received = stats.receivedRecognitions ?? [];
    final filtered = _filterBadge == null
        ? received
        : received.where((r) => r.badge?.name == _filterBadge).toList();

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
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
                  _pill(
                    context,
                    '${stats.receivedCount} Total',
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your badges and recognitions from colleagues',
              style: AppTextStyles.body(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // ── Badge grid ──────────────────────────────────────────
            if (badgeCounts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'No badges yet',
                      style: AppTextStyles.small(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              Builder(builder: (context) {
                // 1. Convert to entries and sort by name for stability
                final sortedEntries = badgeCounts.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                // 2. Interleave to avoid same-colored badges being adjacent
                final displayItems =
                    BadgeUtils.interleaveByColor<MapEntry<String, int>>(
                  sortedEntries,
                  (e) => e.key,
                );

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: displayItems.map((entry) {
                    final name = entry.key;
                    final count = entry.value;
                    final iconUrl = badgeIcons[name];
                    final selected = _filterBadge == name;
                    return _BadgeCountChip(
                      badgeName: name,
                      count: count,
                      iconUrl: iconUrl,
                      isSelected: selected,
                      onTap: () =>
                          setState(() => _filterBadge = selected ? null : name),
                    );
                  }).toList(),
                );
              }),

            const SizedBox(height: 20),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // ── Feed header ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    _filterBadge == null
                        ? 'Received from colleagues'
                        : 'Received — $_filterBadge',
                    style: AppTextStyles.sectionTitle(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_filterBadge != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _filterBadge = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Clear filter',
                              style:
                                  AppTextStyles.small(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Received feed (fixed height) ─────────────────────────
            SizedBox(
              height: 500,
              child: filtered.isEmpty
                  ? Center(
                      child: EmptyStateView(
                        icon: Icons.inbox_outlined,
                        title: _filterBadge == null
                            ? 'No recognitions yet'
                            : 'No recognitions for this badge',
                        padding: 32,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) =>
                          _ReceivedItem(recognition: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyBold(color: textColor),
      ),
    );
  }
}

/// A badge chip with a count bubble in the top-right corner.
class _BadgeCountChip extends StatefulWidget {
  final String badgeName;
  final int count;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _BadgeCountChip({
    required this.badgeName,
    required this.count,
    required this.iconUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BadgeCountChip> createState() => _BadgeCountChipState();
}

class _BadgeCountChipState extends State<_BadgeCountChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final info = BadgeUtils.getDisplayInfo(widget.badgeName);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? info.color.withValues(alpha: 0.12)
                  : (_hovered
                      ? info.color.withValues(alpha: 0.06)
                      : Colors.grey.shade50),
              border: Border.all(
                color: widget.isSelected
                    ? info.color.withValues(alpha: 0.5)
                    : (_hovered
                        ? info.color.withValues(alpha: 0.3)
                        : Colors.grey.shade200),
                width: widget.isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: _badgeIcon(info, widget.iconUrl, 20)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.badgeName,
                      style: AppTextStyles.smallMedium(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.count}×',
                      style: AppTextStyles.captionBold(color: info.color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeIcon(BadgeDisplayInfo info, String? iconUrl, double size) {
    if (iconUrl != null) {
      return Image.network(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => info.hasEmoji
            ? Text(info.emoji!, style: AppTextStyles.emoji())
            : Icon(info.icon, color: info.color, size: size),
      );
    }
    return info.hasEmoji
        ? Text(info.emoji!, style: AppTextStyles.emoji())
        : Icon(info.icon, color: info.color, size: size);
  }
}

/// A single received-recognition feed row
class _ReceivedItem extends StatelessWidget {
  final RecognitionEntity recognition;
  const _ReceivedItem({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final badgeName = recognition.badge?.name ?? 'Badge';
    final info = BadgeUtils.getDisplayInfo(badgeName);
    final pillStyle = BadgeUtils.getPillStyle(badgeName);
    final senderName = recognition.senderName ?? 'Someone';
    final message = recognition.message;
    final timeAgo = _timeAgo(recognition.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: sender avatar + name + badge pill
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: info.color.withValues(alpha: 0.15),
                child: Text(
                  senderName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.label(color: Colors.black87),
                    children: [
                      TextSpan(
                          text: senderName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: ' appreciated you',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Badge pill – constrained so it never overflows narrow screens
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillStyle.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      recognition.badge?.iconUrl != null
                          ? Image.network(
                              recognition.badge!.iconUrl!,
                              width: 12,
                              height: 12,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(pillStyle.icon,
                                  size: 12, color: pillStyle.textColor),
                            )
                          : Icon(pillStyle.icon,
                              size: 12, color: pillStyle.textColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          badgeName.toUpperCase(),
                          style: AppTextStyles.captionBold(
                              color: pillStyle.textColor),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Message
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$message"',
              style: AppTextStyles.small(color: Colors.grey[600])
                  .copyWith(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          // Bottom row: time + points
          Row(
            children: [
              Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(timeAgo,
                  style: AppTextStyles.small(color: Colors.grey[400])),
              if (recognition.pointsAwarded > 0) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${recognition.pointsAwarded} pts',
                    style: AppTextStyles.small(color: info.color)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return DateFormat.yMMMd().format(date);
    if (diff.inDays >= 2) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
