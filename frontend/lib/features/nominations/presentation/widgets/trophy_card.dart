import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';

class TrophyCard extends StatelessWidget {
  final String title;
  final String points;
  final String citation;
  final String from;
  final String date;

  const TrophyCard({
    super.key,
    required this.title,
    required this.points,
    required this.citation,
    required this.from,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft yellow background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF08A), width: 2), // Yellow border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section (Icon + Title + Points)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTextStyles.headline2(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7), // Light green
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      points,
                      style: AppTextStyles.smallBold(color: const Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFFEF08A).withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          
          // Citation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '"$citation"',
              style: AppTextStyles.body(color: Colors.grey[700]).copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'From $from',
                    style: AppTextStyles.smallBold(color: Colors.grey[800]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  date,
                  style: AppTextStyles.small(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
