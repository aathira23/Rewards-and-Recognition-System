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
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'reward_${reward.id}',
                      child: reward.imageUrl != null &&
                              reward.imageUrl!.isNotEmpty
                          ? Image.network(
                              reward.imageUrl!.trim(),
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    'Error loading image ${reward.imageUrl}: $error');
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getIconForCategory(reward.category),
                                        size: 40,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image failed to load',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                _getIconForCategory(reward.category),
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                ),
                // Transparent Ref ID Badge overlayed on image
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ref: #${reward.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          style: AppTextStyles.label().copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(theme, reward.category),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Points and Stock row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Points section
                    Row(
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

                    // Stock indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: reward.stockQuantity > 0
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        reward.stockQuantity > 0
                            ? '${reward.stockQuantity} in stock'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: reward.stockQuantity > 0
                              ? Colors.blue[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed:
                        (hasInsufficientPoints || reward.stockQuantity <= 0)
                            ? null
                            : onRedeem,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: reward.stockQuantity <= 0
                          ? Colors.red.shade50
                          : theme.colorScheme.primary,
                      foregroundColor: reward.stockQuantity <= 0
                          ? Colors.red.shade400
                          : theme.colorScheme.onPrimary,
                      disabledBackgroundColor: reward.stockQuantity <= 0
                          ? Colors.red.shade50
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      disabledForegroundColor: reward.stockQuantity <= 0
                          ? Colors.red.shade400
                          : theme.hintColor,
                    ),
                    child: Text(
                      reward.stockQuantity <= 0
                          ? 'Out of Stock'
                          : (hasInsufficientPoints
                              ? 'Short on Points'
                              : 'Redeem Now'),
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
