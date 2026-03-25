import 'package:flutter/material.dart';

/// "A simple model defining a navigation destination for the app sidebar."
class NavDestination {
  final String title;

  /// Full heading shown in the top bar (defaults to [title] if null).
  final String? heading;

  /// Subtitle shown below the heading in the top bar.
  final String? subtitle;
  final IconData icon;
  final Widget page;

  /// Whether this tab is hidden from the sidebar lists.
  final bool isHidden;

  const NavDestination({
    required this.title,
    this.heading,
    this.subtitle,
    required this.icon,
    required this.page,
    this.isHidden = false,
  });
}
