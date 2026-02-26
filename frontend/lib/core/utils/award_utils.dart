import 'package:flutter/material.dart';

/// Centralized mapping of award keys to icons and colors.
class AwardUtils {
  AwardUtils._();

  static IconData getIcon(String awardKey) {
    switch (awardKey.toLowerCase()) {
      case 'employee_of_month':
      case 'employee_of_quarter':
      case 'employee_of_year':
        return Icons.workspace_premium_rounded;
      case 'innovation':
        return Icons.lightbulb_rounded;
      case 'teamwork':
      case 'collaboration':
        return Icons.groups_rounded;
      case 'leadership':
        return Icons.star_rounded;
      case 'customer':
        return Icons.handshake_rounded;
      case 'excellence':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  static Color getColor(String awardKey) {
    switch (awardKey.toLowerCase()) {
      case 'employee_of_month':
        return Colors.amber.shade700;
      case 'employee_of_quarter':
        return Colors.orange.shade600;
      case 'employee_of_year':
        return Colors.deepOrange.shade600;
      case 'innovation':
        return Colors.purple.shade600;
      case 'teamwork':
      case 'collaboration':
        return Colors.teal.shade600;
      case 'leadership':
        return Colors.blue.shade700;
      case 'customer':
        return Colors.green.shade600;
      case 'excellence':
        return const Color(0xFF1E56BD);
      default:
        return Colors.indigo.shade500;
    }
  }
}
