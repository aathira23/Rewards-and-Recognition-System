import 'package:flutter/material.dart';

/// A consistent Approve button used across the application.
class ApproveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isCompact;
  final String? tooltip;
  final bool useFilledStyle;

  const ApproveButton({
    super.key,
    required this.onPressed,
    this.label = 'Approve',
    this.isCompact = false,
    this.tooltip,
    this.useFilledStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, color: Colors.green),
        tooltip: tooltip ?? label,
      );
    }

    if (useFilledStyle) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check_rounded, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
      ),
    );
  }
}

/// A consistent Reject button used across the application.
class RejectButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isCompact;
  final String? tooltip;
  final bool useFilledStyle;

  const RejectButton({
    super.key,
    required this.onPressed,
    this.label = 'Reject',
    this.isCompact = false,
    this.tooltip,
    this.useFilledStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, color: Colors.red),
        tooltip: tooltip ?? label,
      );
    }

    if (useFilledStyle) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.close_rounded, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
    );
  }
}
