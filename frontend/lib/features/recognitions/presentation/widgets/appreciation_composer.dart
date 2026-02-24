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
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Send an Appreciation',
                    style: AppTextStyles.pageTitle(),
                  ),
                  TextButton(
                    onPressed: () => _showSentAppreciationsDialog(context),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Appreciations Sent',
                      style: AppTextStyles.bodyBold(
                        color: const Color(0xFF1A60FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a badge to appreciate someone',
              style: AppTextStyles.body(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
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
          children: [
            // Icon section - standard height
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
                    child: badge.iconUrl != null
                        ? ClipOval(
                            child: Image.network(
                              badge.iconUrl!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => badgeInfo.hasEmoji
                                  ? Text(badgeInfo.emoji!,
                                      style: AppTextStyles.emoji())
                                  : Icon(badgeInfo.icon,
                                      color: badgeInfo.color, size: 28),
                            ),
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
            // Name section - standard 2-line height
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  badge.name,
                  style: AppTextStyles.cardTitle(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Spacer(),
            // Points section
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
