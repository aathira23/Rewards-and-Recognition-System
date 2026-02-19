import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          color: Colors.white,
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
                const Text(
                  'Send an Appreciation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showSentAppreciationsDialog(context),
                  child: const Text(
                    'Appreciations Sent',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A60FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a badge to appreciate someone',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
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
    final badgeInfo = _getBadgeInfo(badge.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
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
                child: badgeInfo.isEmoji
                    ? Text(
                        badgeInfo.emoji!,
                        style: const TextStyle(fontSize: 28),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${badgeInfo.points} pts',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BadgeDetails _getBadgeInfo(String badgeName) {
    switch (badgeName.toLowerCase()) {
      case 'you rock !!!':
        return const _BadgeDetails(
          emoji: '👍',
          color: Colors.amber,
          points: 50,
        );
      case 'out of box thinker !!!':
        return const _BadgeDetails(
          emoji: '💡',
          color: Colors.purple,
          points: 75,
        );
      case 'bright spark !!!':
        return const _BadgeDetails(
          emoji: '💖',
          color: Colors.pink,
          points: 50,
        );
      case 'great team player !!!':
        return const _BadgeDetails(
          emoji: '👥',
          color: Color(0xFF1B60FF),
          points: 60,
        );
      case 'invaluable help !!!':
        return const _BadgeDetails(
          emoji: '💎',
          color: Colors.cyan,
          points: 50,
        );
      case 'agility champion !!!':
        return const _BadgeDetails(
          emoji: '⚡',
          color: Colors.blue,
          points: 70,
        );
      case 'trust builder !!!':
        return const _BadgeDetails(
          emoji: '🛡️',
          color: Colors.lightBlue,
          points: 65,
        );
      case 'partnership pioneer !!!':
        return const _BadgeDetails(
          emoji: '🎯',
          color: Colors.redAccent,
          points: 80,
        );
      default:
        return const _BadgeDetails(
          icon: Icons.stars_outlined,
          color: Colors.blue,
          points: 50,
        );
    }
  }
}

class _BadgeDetails {
  final String? emoji;
  final IconData? icon;
  final Color color;
  final int points;

  const _BadgeDetails({
    this.emoji,
    this.icon,
    required this.color,
    required this.points,
  });

  bool get isEmoji => emoji != null;
}
