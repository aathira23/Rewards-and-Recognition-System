import 'package:flutter/material.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/recognition_entity.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';

class RecognitionFeedList extends StatelessWidget {
  final List<RecognitionEntity> feed;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const RecognitionFeedList({
    super.key,
    required this.feed,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return const EmptyStateView(
        icon: Icons.feed_outlined,
        title: 'No recognitions yet',
        message: 'Be the first to appreciate someone!',
        padding: 40,
      );
    }

    return ListView.builder(
      itemCount: feed.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        final r = feed[index];
        final type = (r.sourceType ?? 'ECARD').toUpperCase();
        return _FeedItem(recognition: r, type: type);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified feed card — identical container, content differs per type
// ─────────────────────────────────────────────────────────────────────────────
class _FeedItem extends StatelessWidget {
  final RecognitionEntity recognition;
  final String type;

  const _FeedItem({required this.recognition, required this.type});

  @override
  Widget build(BuildContext context) {
    final senderName = recognition.senderName ?? 'Someone';
    final receiverName = recognition.receiverName ?? 'Someone';
    final message = recognition.message ?? '';
    final timeAgo = _timeAgo(recognition.createdAt);
    final badgeName = recognition.badge?.name ?? '';

    // Per-type config
    final Color iconBg;
    final Widget iconChild;
    final Widget titleLine;
    late Widget tagLine;

    if (type == 'AWARD') {
      const c = Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
      iconChild = const Icon(Icons.emoji_events_rounded, color: c, size: 20);
      titleLine = _nameText(receiverName, ' received a formal award');
      tagLine = _Tag(
        label: message.isNotEmpty ? message : 'Award',
        color: c,
        icon: Icons.emoji_events_rounded,
      );
    } else if (type == 'CELEBRATION') {
      const c = Color(0xFF7C3AED);
      final msgLower = message.toLowerCase();
      final isBirthday = msgLower.contains('birthday');
      final isNewBaby = msgLower.contains('baby') || msgLower.contains('birth');
      final isMarriage =
          msgLower.contains('marriage') || msgLower.contains('married');

      final IconData celebIcon = isBirthday
          ? Icons.cake_rounded
          : isNewBaby
              ? Icons.child_friendly_rounded
              : isMarriage
                  ? Icons.favorite_rounded
                  : Icons.workspace_premium_rounded;

      final String celebLabel = isBirthday
          ? 'Birthday 🎂'
          : isNewBaby
              ? 'New Baby 🍼'
              : isMarriage
                  ? 'Marriage 💍'
                  : 'Work Anniversary 🌟';

      iconBg = const Color(0xFFEDE9FE);
      iconChild = Icon(celebIcon, color: c, size: 20);
      titleLine = _nameText(receiverName, "'s special day");
      tagLine = _Tag(
        label: celebLabel,
        color: c,
        icon: celebIcon,
      );
    } else {
      // ECARD
      const c = Color(0xFF3B82F6);
      iconBg = const Color(0xFFDBEAFE);
      iconChild = Text(
        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
        style: const TextStyle(
            color: c, fontWeight: FontWeight.w700, fontSize: 15),
      );
      titleLine = _ecardTitle(senderName, receiverName, c);
      if (badgeName.isNotEmpty) {
        final ps = BadgeUtils.getPillStyle(badgeName);
        tagLine = _BadgePill(
            badgeName: badgeName, pillStyle: ps, badge: recognition.badge);
      } else {
        tagLine = const SizedBox.shrink();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon tile
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: iconChild,
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name line + timestamp on same row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleLine),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: AppTextStyles.small(color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // Tag / badge pill
                tagLine,

                // Message (ECARD only)
                if (type == 'ECARD' && message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"$message"',
                    style: AppTextStyles.small(color: Colors.grey[500])
                        .copyWith(fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small widget helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _nameText(String bold, String normal) => RichText(
      text: TextSpan(
        style:
            const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
        children: [
          TextSpan(
              text: bold, style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(
              text: normal, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );

Widget _ecardTitle(String sender, String receiver, Color accentColor) =>
    RichText(
      text: TextSpan(
        style:
            const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
        children: [
          TextSpan(
              text: sender,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const TextSpan(
              text: ' appreciated ',
              style: TextStyle(color: Color(0xFF6B7280))),
          TextSpan(
              text: receiver,
              style:
                  TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Tag({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String badgeName;
  final BadgePillStyle pillStyle;
  final dynamic badge;

  const _BadgePill(
      {required this.badgeName, required this.pillStyle, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pillStyle.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge?.iconUrl != null
              ? Image.network(
                  badge!.iconUrl!,
                  width: 12,
                  height: 12,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(pillStyle.icon,
                      size: 12, color: pillStyle.textColor),
                )
              : Icon(pillStyle.icon, size: 12, color: pillStyle.textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              badgeName.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: pillStyle.textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 7) return DateFormat.yMMMd().format(date);
  if (diff.inDays >= 2) return '${diff.inDays} days ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}
