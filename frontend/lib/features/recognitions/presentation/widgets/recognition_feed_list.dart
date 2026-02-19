import 'package:flutter/material.dart';
import '../../domain/entities/recognition_entity.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';

class RecognitionFeedList extends StatelessWidget {
  final List<RecognitionEntity> feed;

  const RecognitionFeedList({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.feed_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No recognitions yet',
                style: AppTextStyles.sectionTitle(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to appreciate someone!',
                style: AppTextStyles.bodyLarge(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: feed.length,
      itemBuilder: (context, index) {
        final recognition = feed[index];
        return _buildFeedItem(context, recognition);
      },
    );
  }

  Widget _buildFeedItem(BuildContext context, RecognitionEntity recognition) {
    final senderName = recognition.senderName ?? 'User ${recognition.senderId}';
    final receiverName =
        recognition.receiverName ?? 'User ${recognition.receiverId}';
    final badgeName = recognition.badge?.name ?? 'Appreciation';
    final timeAgo = _getTimeAgo(recognition.createdAt);

    // Dynamic Badge Colors
    final badgeStyle = _getBadgeStyle(badgeName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Light Blue tint
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              senderName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.sectionHeader(
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Sender appreciated Receiver
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.label(
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: senderName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' appreciated ',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      TextSpan(
                        text: receiverName,
                        style: const TextStyle(
                          color: Color(0xFF2962FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Badge Pill
                if (recognition.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getBadgeIcon(badgeName),
                          size: 14,
                          color: badgeStyle.textColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeName.toUpperCase(),
                          style: AppTextStyles.captionBold(
                            color: badgeStyle.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Message
                if (recognition.message != null &&
                    recognition.message!.isNotEmpty)
                  Text(
                    '"${recognition.message}"',
                    style: AppTextStyles.bodyLarge(
                      color: const Color(0xFF546E7A),
                    ),
                  ),
                const SizedBox(height: 12),
                // Timestamp
                Text(
                  timeAgo,
                  style: AppTextStyles.small(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }
      return DateFormat.yMMMd().format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  BadgeStyle _getBadgeStyle(String badgeName) {
    final name = badgeName.toLowerCase();
    if (name.contains('star') || name.contains('spark')) {
      return BadgeStyle(
        backgroundColor: const Color(0xFFFCE4EC), // Pink 50
        textColor: const Color(0xFFEc407A), // Pink 400
      );
    } else if (name.contains('help') || name.contains('assist')) {
      return BadgeStyle(
        backgroundColor: const Color(0xFFE8F5E9), // Green 50
        textColor: const Color(0xFF66BB6A), // Green 400
      );
    } else if (name.contains('team') || name.contains('player')) {
      return BadgeStyle(
        backgroundColor: const Color(0xFFE3F2FD), // Blue 50
        textColor: const Color(0xFF42A5F5), // Blue 400
      );
    } else {
      // Default
      return BadgeStyle(
        backgroundColor: const Color(0xFFF3E5F5), // Purple 50
        textColor: const Color(0xFFAB47BC), // Purple 400
      );
    }
  }

  IconData _getBadgeIcon(String badgeName) {
    final name = badgeName.toLowerCase();
    if (name.contains('star') || name.contains('spark')) {
      return Icons.electric_bolt_rounded;
    } else if (name.contains('help')) {
      return Icons.handshake_rounded;
    } else if (name.contains('team')) {
      return Icons.groups_rounded;
    }
    return Icons.star_rounded;
  }
}

class BadgeStyle {
  final Color backgroundColor;
  final Color textColor;

  BadgeStyle({required this.backgroundColor, required this.textColor});
}
