import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../../../core/utils/badge_utils.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/entities/badge_entity.dart';
import '../bloc/recognitions_bloc.dart';
import '../bloc/recognitions_state.dart';
import 'sent_recognitions_list.dart';

class AppreciationComposer extends StatelessWidget {
  final List<BadgeEntity> badges;
  final Function(BadgeEntity) onBadgeSelected;

  const AppreciationComposer({
    super.key,
    required this.badges,
    required this.onBadgeSelected,
  });

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
                Text(
                  'Send an Appreciation',
                  style: AppTextStyles.pageTitle(),
                ),
                TextButton(
                  onPressed: () => _showSentAppreciationsDialog(context),
                  child: Text(
                    'Appreciations Sent',
                    style: AppTextStyles.bodyBold(
                      color: const Color(0xFF1A60FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a badge to appreciate someone',
              style: AppTextStyles.body(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.15,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _BadgeCard(
                  badge: badge,
                  onTap: () => onBadgeSelected(badge),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSentAppreciationsDialog(BuildContext context) {
    final bloc = context.read<RecognitionsBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AppDialog(
          title: 'Appreciations Sent',
          content: BlocBuilder<RecognitionsBloc, RecognitionsState>(
            builder: (context, state) {
              final recognitions = state.stats?.sentRecognitions ?? [];
              return SentRecognitionsList(recognitions: recognitions);
            },
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeEntity badge;
  final VoidCallback onTap;

  const _BadgeCard({
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeInfo = BadgeUtils.getDisplayInfo(badge.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: badgeInfo.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badgeInfo.hasEmoji
                    ? Text(
                        badgeInfo.emoji!,
                        style: AppTextStyles.emoji(),
                      )
                    : Icon(
                        badgeInfo.icon,
                        color: badgeInfo.color,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: AppTextStyles.cardTitle(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${badge.points ?? 50} pts',
              style: AppTextStyles.bodyMedium(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
