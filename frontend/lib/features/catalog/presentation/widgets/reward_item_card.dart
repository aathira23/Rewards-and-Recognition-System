import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/reward_entity.dart';

class RewardItemCard extends StatelessWidget {
  final RewardEntity reward;
  final bool hasInsufficientPoints;
  final VoidCallback onRedeem;

  const RewardItemCard({
    super.key,
    required this.reward,
    required this.hasInsufficientPoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Icon Container
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Hero(
                  tag: 'reward_${reward.id}',
                  child: Icon(
                    _getIconForCategory(reward.category),
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name section - standard 2-line height for uniformity
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          reward.name,
                          style: AppTextStyles.label(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(theme, reward.category),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Points section
                SizedBox(
                  height: 32,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        reward.pointsCost.toString(),
                        style: AppTextStyles.headline2(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'pts',
                          style: AppTextStyles.smallMedium(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: hasInsufficientPoints ? null : onRedeem,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      disabledForegroundColor: theme.hintColor,
                    ),
                    child: Text(
                      hasInsufficientPoints ? 'Short on Points' : 'Redeem Now',
                      style: AppTextStyles.bodyBold(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('vouch') || cat.contains('card'))
      return Icons.confirmation_number_rounded;
    if (cat.contains('merch')) return Icons.shopping_bag_rounded;
    if (cat.contains('tech')) return Icons.devices_rounded;
    if (cat.contains('exp')) return Icons.map_rounded;
    return Icons.redeem_rounded;
  }

  Widget _buildCategoryBadge(ThemeData theme, String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: AppTextStyles.tiny(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
