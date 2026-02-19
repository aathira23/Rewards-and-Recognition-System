import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';

class LeaderboardPanel extends StatelessWidget {
  final List<LeaderboardEntryEntity> entries;
  final String currentPeriod;
  final Function(String) onPeriodChanged;

  const LeaderboardPanel({
    super.key,
    required this.entries,
    required this.currentPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Leaderboard',
                  style: AppTextStyles.pageTitle(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPeriodToggle(),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No data available'),
                ),
              )
            else
              Column(
                children: entries
                    .map((entry) => _buildLeaderboardItem(context, entry))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleButton('Monthly', 'MONTHLY'),
          _buildToggleButton('All Time', 'ALL_TIME'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String value) {
    final isSelected = currentPeriod == value;
    return Expanded(
      child: InkWell(
        onTap: () => onPeriodChanged(value),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: isSelected
                ? AppTextStyles.bodyBold(color: Colors.black87)
                : AppTextStyles.body(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(
      BuildContext context, LeaderboardEntryEntity entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: _getRankIcon(entry.rank),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              entry.name.isNotEmpty
                  ? entry.name.substring(0, 1).toUpperCase()
                  : '?',
              style: AppTextStyles.cardTitle(
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: AppTextStyles.cardTitle(),
                ),
                Text(
                  '${entry.score} points',
                  style: AppTextStyles.small(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getRankIcon(int rank) {
    if (rank == 1)
      return const Icon(Icons.emoji_events, color: Colors.orange, size: 20);
    if (rank == 2)
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 20);
    if (rank == 3)
      return const Icon(Icons.emoji_events, color: Colors.brown, size: 20);
    return Text(
      rank.toString(),
      style: AppTextStyles.cardTitle(
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }
}
