import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final theme = Theme.of(context);

    return Card(
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
                  onPressed: () => _showSentAppreciationsDialog(context),
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
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1)),
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
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appreciations Sent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black12,
                        child:
                            Icon(Icons.close, size: 20, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: BlocBuilder<RecognitionsBloc, RecognitionsState>(
                    builder: (context, state) {
                      final recognitions = state.stats?.sentRecognitions ?? [];
                      return SingleChildScrollView(
                        child: SentRecognitionsList(recognitions: recognitions),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
