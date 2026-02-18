import 'package:flutter/material.dart';
import '../../domain/entities/points_summary_entity.dart';

class PointsSummaryCard extends StatelessWidget {
  final PointsSummaryEntity summary;

  const PointsSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Points Wallet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary.balance.toString(),
            style: const TextStyle(
              fontSize: 42,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Total Points',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStat(
                  'Total Earned',
                  summary.totalEarned.toString(),
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildSecondaryStat(
                  'Total Redeemed',
                  summary.totalRedeemed.toString(),
                  Icons.shopping_bag_outlined,
                ),
              ),
              Expanded(
                child: _buildSecondaryStat(
                  'Expiring Soon',
                  summary.pendingCount.toString(),
                  Icons.info_outline,
                  subLabel: 'by Mar 30, 2026',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(String label, String value, IconData icon,
      {String? subLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subLabel != null)
          Text(
            subLabel,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
      ],
    );
  }
}
