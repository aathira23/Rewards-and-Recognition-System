/// Centralized badge visual mapping to eliminate duplication across widgets.
///
/// Used by: appreciation_composer, appreciation_stats,
///          sent_recognitions_list, recognition_feed_list.
///
/// Colours are assigned by cycling through 4 fixed palettes based on the
/// badge name's hash code — no hardcoded names, works with any badge from
/// any system. Same badge name always resolves to the same palette.
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 4 rotating display palettes
// ─────────────────────────────────────────────────────────────────────────────
const _kDisplayPalettes = [
  // 0 — Blue
  BadgeDisplayInfo(
    emoji: '⭐',
    icon: Icons.stars_outlined,
    color: Color.fromARGB(255, 230, 86, 198),
  ),
  // 1 — Purple
  BadgeDisplayInfo(
    emoji: '💡',
    icon: Icons.lightbulb_outline,
    color: Color.fromARGB(255, 67, 11, 163),
  ),
  // 2 — Amber
  BadgeDisplayInfo(
    emoji: '🏆',
    icon: Icons.emoji_events_outlined,
    color: Color(0xFFD97706),
  ),
  // 3 — Green
  BadgeDisplayInfo(
    emoji: '🚀',
    icon: Icons.rocket_launch_outlined,
    color: Color(0xFF059669),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// 4 rotating pill palettes (background is a tint of the accent, text is accent)
// ─────────────────────────────────────────────────────────────────────────────
const _kPillPalettes = [
  // 0 — Blue
  BadgePillStyle(
    backgroundColor: Color(0xFFEFF6FF),
    textColor: Color(0xFF3B82F6),
    icon: Icons.stars_rounded,
  ),
  // 1 — Purple
  BadgePillStyle(
    backgroundColor: Color(0xFFF5F3FF),
    textColor: Color(0xFF7C3AED),
    icon: Icons.lightbulb_rounded,
  ),
  // 2 — Amber
  BadgePillStyle(
    backgroundColor: Color(0xFFFFFBEB),
    textColor: Color(0xFFD97706),
    icon: Icons.emoji_events_rounded,
  ),
  // 3 — Green
  BadgePillStyle(
    backgroundColor: Color(0xFFECFDF5),
    textColor: Color(0xFF059669),
    icon: Icons.rocket_launch_rounded,
  ),
];

class BadgeUtils {
  BadgeUtils._();

  // ── Position-based (use when rendering an ordered list/grid) ──────────────
  //
  // Cycles 0→1→2→3→0→1→2→3... so adjacent badges are always different colours.

  /// Display info by position index in a list/grid.
  static BadgeDisplayInfo getDisplayInfoByIndex(int index) =>
      _kDisplayPalettes[index % 4];

  /// Pill styling by position index in a list/grid.
  static BadgePillStyle getPillStyleByIndex(int index) =>
      _kPillPalettes[index % 4];

  // ── Name-based (use when rendering a single badge without list context) ───
  //
  // Deterministic: same name always resolves to the same palette.

  /// Returns the 0-based palette index (0–3) for a given badge name.
  static int _paletteIndex(String badgeName) =>
      badgeName.toLowerCase().hashCode.abs() % 4;

  /// Display info (emoji, icon, color) for a badge by name.
  static BadgeDisplayInfo getDisplayInfo(String badgeName) =>
      _kDisplayPalettes[_paletteIndex(badgeName)];

  /// Pill styling for a badge by name.
  static BadgePillStyle getPillStyle(String badgeName) =>
      _kPillPalettes[_paletteIndex(badgeName)];

  /// Reorders a list of items to ensure that items with the same color palette
  /// are not adjacent, improving visual diversity in grids/rows.
  ///
  /// Uses a round-robin interleaving strategy based on the 4 available palettes.
  static List<T> interleaveByColor<T>(
    List<T> items,
    String Function(T) getName,
  ) {
    if (items.length <= 1) return items;

    // 1. Group items by their palette index
    final buckets = List.generate(4, (_) => <T>[]);
    for (final item in items) {
      final idx = _paletteIndex(getName(item));
      buckets[idx].add(item);
    }

    // 2. Interleave by round-robin
    final result = <T>[];
    bool added;
    do {
      added = false;
      for (int i = 0; i < 4; i++) {
        if (buckets[i].isNotEmpty) {
          result.add(buckets[i].removeAt(0));
          added = true;
        }
      }
    } while (added);

    return result;
  }
}

/// Display info for badge cards, stats, and recognition lists.
class BadgeDisplayInfo {
  /// Emoji for the badge (used in badge cards).
  final String? emoji;

  /// Icon for the badge (used in stats and recognition lists).
  final IconData icon;

  /// Primary color (used for emoji background in badge cards).
  final Color color;

  /// Separate color for icon-only contexts (stats, sent list).
  /// Falls back to [color] if null.
  final Color? iconColor;

  const BadgeDisplayInfo({
    this.emoji,
    required this.icon,
    required this.color,
    this.iconColor,
  });

  /// Whether this badge has an emoji representation.
  bool get hasEmoji => emoji != null;

  /// The color to use for icon display contexts.
  Color get effectiveIconColor => iconColor ?? color;
}

/// Styling for badge pills in recognition feed items.
class BadgePillStyle {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const BadgePillStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
