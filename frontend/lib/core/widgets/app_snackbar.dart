import 'package:flutter/material.dart';

/// Unified snackbar feedback for the entire app.
///
/// Use these static methods instead of constructing SnackBars inline:
///   AppSnackbar.success(context, 'Saved!');
///   AppSnackbar.error(context, 'Something went wrong');
///   AppSnackbar.warning(context, 'Points are expiring soon');
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, Colors.green, Icons.check_circle_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, Colors.redAccent, Icons.error_rounded);

  static void warning(BuildContext context, String message) =>
      _show(context, message, Colors.orange, Icons.warning_amber_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
