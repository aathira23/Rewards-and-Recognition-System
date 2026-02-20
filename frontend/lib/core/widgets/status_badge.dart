import 'package:flutter/material.dart';

/// A standardized badge/pill used to display the status of a record.
class StatusBadge extends StatelessWidget {
  final String status;

  /// Optional custom label. If null, the [status] will be used.
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final displayLabel = label ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'APPROVED':
      case 'ACTIVE':
      case 'SUCCESS':
      case 'EARNED':
      case 'RECEIVED':
      case 'COMPLETED':
        return const Color(0xFF16A34A); // Green
      case 'REJECTED':
      case 'CANCELLED':
      case 'FAILED':
      case 'ERROR':
      case 'EXPIRED':
        return const Color(0xFFDC2626); // Red
      case 'PENDING':
      case 'IN_PROGRESS':
      case 'WAITING':
      case 'REDEEMED':
      case 'SPENT':
        return const Color(0xFFF59E0B); // Orange
      case 'INFO':
      case 'PAUSED':
        return const Color(0xFF2563EB); // Blue
      default:
        return Colors.grey.shade600;
    }
  }
}
