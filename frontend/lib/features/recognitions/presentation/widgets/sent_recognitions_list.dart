import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/recognition_entity.dart';

class SentRecognitionsList extends StatelessWidget {
  final List<RecognitionEntity> recognitions;

  const SentRecognitionsList({
    super.key,
    required this.recognitions,
  });

  @override
  Widget build(BuildContext context) {
    if (recognitions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'You haven\'t sent any appreciations yet.',
            style: AppTextStyles.body(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: recognitions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final recognition = recognitions[index];
        return _SentRecognitionTile(recognition: recognition);
      },
    );
  }
}

class _SentRecognitionTile extends StatelessWidget {
  final RecognitionEntity recognition;

  const _SentRecognitionTile({required this.recognition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM dd, yyyy').format(recognition.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              recognition.receiverName != null &&
                      recognition.receiverName!.isNotEmpty
                  ? recognition.receiverName!.substring(0, 1).toUpperCase()
                  : 'U',
              style: AppTextStyles.bodyBold(
                color: theme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'To: ${recognition.receiverName ?? 'Unknown'}',
                        style: AppTextStyles.label(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: AppTextStyles.small(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _getBadgeIcon(recognition.badge?.name ?? ''),
                    const SizedBox(width: 8),
                    Text(
                      recognition.badge?.name ?? 'Badge',
                      style: AppTextStyles.bodyMedium(
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (recognition.message != null &&
                    recognition.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    recognition.message!,
                    style: AppTextStyles.body(
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBadgeIcon(String badgeName) {
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

    return Icon(icon, color: color, size: 16);
  }
}
