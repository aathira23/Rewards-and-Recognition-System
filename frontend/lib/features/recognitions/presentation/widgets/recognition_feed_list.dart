import 'package:flutter/material.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../domain/entities/recognition_entity.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';

class RecognitionFeedList extends StatelessWidget {
  final List<RecognitionEntity> feed;

  const RecognitionFeedList({super.key, required this.feed});

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

    // Badge pill styling from shared utility
    final pillStyle = BadgeUtils.getPillStyle(badgeName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                      color: pillStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        recognition.badge?.iconUrl != null
                            ? Image.network(
                                recognition.badge!.iconUrl!,
                                width: 14,
                                height: 14,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  pillStyle.icon,
                                  size: 14,
                                  color: pillStyle.textColor,
                                ),
                              )
                            : Icon(
                                pillStyle.icon,
                                size: 14,
                                color: pillStyle.textColor,
                              ),
                        const SizedBox(width: 6),
                        Text(
                          badgeName.toUpperCase(),
                          style: AppTextStyles.captionBold(
                            color: pillStyle.textColor,
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
}
