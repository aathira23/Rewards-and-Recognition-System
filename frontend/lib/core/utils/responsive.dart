import 'package:flutter/material.dart';

/// Centralised breakpoint helper for the entire app.
///
/// Breakpoints (max-width):
/// - Mobile  : < 768
/// - Tablet  : 768 – 1099
/// - Desktop : ≥ 1100
///
/// The sidebar uses its own 900 px breakpoint via [showSidebar].
class Responsive {
  Responsive._();

  // ─── Breakpoints ────────────────────────────────────────────────
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1100;
  static const double sidebarBreakpoint = 900;

  // ─── Queries ────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobileBreakpoint && w < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Whether the persistent sidebar should be visible.
  static bool showSidebar(BuildContext context) =>
      MediaQuery.of(context).size.width > sidebarBreakpoint;

  // ─── Adaptive values ───────────────────────────────────────────
  /// Page-level padding: 16 on mobile, 20 on tablet, 24 on desktop.
  static double pagePadding(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  /// Number of grid columns for card grids.
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Returns [mobile] on phones, [tablet] on tablets, [desktop] on desktops.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }
}

/// A layout widget that renders its children in a [Row] on wide screens
/// and in a [Column] on narrow screens.
///
/// The [breakWidth] defaults to [Responsive.mobileBreakpoint] (768).
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final double breakWidth;
  final MainAxisAlignment rowMainAxisAlignment;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final MainAxisAlignment columnMainAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;

  /// Gap between children — used as horizontal gap in row mode
  /// and vertical gap in column mode.
  final double spacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.breakWidth = Responsive.mobileBreakpoint,
    this.spacing = 24,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.start,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakWidth) {
          // Row mode (desktop / tablet)
          return Row(
            mainAxisAlignment: rowMainAxisAlignment,
            crossAxisAlignment: rowCrossAxisAlignment,
            children: _intersperse(SizedBox(width: spacing), children),
          );
        }
        // Column mode (mobile)
        return Column(
          mainAxisAlignment: columnMainAxisAlignment,
          crossAxisAlignment: columnCrossAxisAlignment,
          children: _intersperse(SizedBox(height: spacing), children),
        );
      },
    );
  }

  /// Inserts [separator] between each element of [list].
  List<Widget> _intersperse(Widget separator, List<Widget> list) {
    if (list.length <= 1) return list;
    final result = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      result.add(list[i]);
      if (i < list.length - 1) result.add(separator);
    }
    return result;
  }
}
