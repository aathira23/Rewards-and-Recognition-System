import 'package:flutter/material.dart';
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

  static const _primary = Color(0xFF3B31A5);

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = reward.stockQuantity <= 0;
    final bool disabled = hasInsufficientPoints || outOfStock;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image area with points badge ──
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox.expand(
                    child: reward.imageUrl != null &&
                            reward.imageUrl!.isNotEmpty
                        ? Image.network(
                            reward.imageUrl!.trim(),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                // Points badge – top right corner
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${reward.pointsCost} pts',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 59, 49, 165),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category label
                Text(
                  _displayCategory(reward.category),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Product name
                Text(
                  reward.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Redeem button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: disabled ? null : onRedeem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: const Color(0xFF9E9E9E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      outOfStock
                          ? 'Out of Stock'
                          : hasInsufficientPoints
                              ? 'Insufficient Points'
                              : 'Redeem',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          _iconForCategory(reward.category),
          size: 52,
          color: _primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  String _displayCategory(String raw) {
    final map = {
      'GIFT_CARD': 'Gift Cards',
      'MERCH': 'Merchandise',
      'EXPERIENCE': 'Experiences',
      'EXPERIENCES': 'Experiences',
      'CHARITY': 'Charity',
    };
    return map[raw.toUpperCase()] ?? raw;
  }

  IconData _iconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('gift') || cat.contains('card'))
      return Icons.confirmation_number_rounded;
    if (cat.contains('merch')) return Icons.shopping_bag_rounded;
    if (cat.contains('exp')) return Icons.map_rounded;
    if (cat.contains('char')) return Icons.volunteer_activism_rounded;
    return Icons.redeem_rounded;
  }
}
