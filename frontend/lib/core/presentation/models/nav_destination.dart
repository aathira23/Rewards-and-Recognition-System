import 'package:flutter/material.dart';

/// "A simple model defining a navigation destination for the app sidebar."
class NavDestination {
  final String title;
  final IconData icon;
  final Widget page;

  const NavDestination({
    required this.title,
    required this.icon,
    required this.page,
  });
}
