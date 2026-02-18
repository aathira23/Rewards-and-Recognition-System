import 'package:flutter/material.dart';
import '../../domain/entities/badge_entity.dart';

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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Send an Appreciation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {}, // TODO: View Appreciations Sent
                  child: const Text('Appreciations Sent'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a badge to appreciate someone',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return InkWell(
                  onTap: () => onBadgeSelected(badge),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getBadgeIcon(badge.name),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            badge.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Full send recognition flow
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Recognition'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBadgeIcon(String badgeName) {
    // Placeholder logic for badge icons matched from mockup
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

    return Icon(icon, color: color, size: 20);
  }
}
