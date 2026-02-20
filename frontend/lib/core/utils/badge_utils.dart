/// Centralized badge visual mapping to eliminate duplication across widgets.
///
/// Used by: appreciation_composer, appreciation_stats,
///          sent_recognitions_list, recognition_feed_list.
import 'package:flutter/material.dart';

class BadgeUtils {
  BadgeUtils._();

  /// Get display info for a badge by name.
  /// Returns emoji, fallback icon, and colors for different display contexts.
  static BadgeDisplayInfo getDisplayInfo(String badgeName) {
    switch (badgeName.toLowerCase()) {
      case 'you rock !!!':
        return const BadgeDisplayInfo(
          emoji: '👍',
          icon: Icons.thumb_up_alt_outlined,
          color: Colors.amber,
          iconColor: Colors.green,
        );
      case 'out of box thinker !!!':
        return const BadgeDisplayInfo(
          emoji: '💡',
          icon: Icons.lightbulb_outline,
          color: Colors.purple,
        );
      case 'bright spark !!!':
        return const BadgeDisplayInfo(
          emoji: '💖',
          icon: Icons.lightbulb_outline,
          color: Colors.pink,
        );
      case 'great team player !!!':
        return const BadgeDisplayInfo(
          emoji: '👥',
          icon: Icons.groups_outlined,
          color: Color(0xFF1B60FF),
          iconColor: Colors.orange,
        );
      case 'invaluable help !!!':
        return const BadgeDisplayInfo(
          emoji: '💎',
          icon: Icons.diamond_outlined,
          color: Colors.cyan,
        );
      case 'agility champion !!!':
        return const BadgeDisplayInfo(
          emoji: '⚡',
          icon: Icons.bolt_rounded,
          color: Colors.blue,
        );
      case 'trust builder !!!':
        return const BadgeDisplayInfo(
          emoji: '🛡️',
          icon: Icons.shield_outlined,
          color: Colors.lightBlue,
        );
      case 'partnership pioneer !!!':
        return const BadgeDisplayInfo(
          emoji: '🎯',
          icon: Icons.track_changes_rounded,
          color: Colors.redAccent,
        );
      case 'customer hero !!!':
        return const BadgeDisplayInfo(
          emoji: '🦸',
          icon: Icons.person_outline_rounded,
          color: Colors.teal,
        );
      case 'star of innovation !!!':
        return const BadgeDisplayInfo(
          emoji: '⭐',
          icon: Icons.star_outline_rounded,
          color: Colors.orange,
        );
      case 'heartfelt apology !!':
        return const BadgeDisplayInfo(
          emoji: '🙏',
          icon: Icons.favorite_outline_rounded,
          color: Colors.deepPurple,
        );
      default:
        return const BadgeDisplayInfo(
          icon: Icons.stars_outlined,
          color: Colors.blue,
        );
    }
  }

  /// Get pill/chip styling for badge in recognition feed.
  /// Uses pattern-based matching for badge category styling.
  static BadgePillStyle getPillStyle(String badgeName) {
    final name = badgeName.toLowerCase();
    if (name.contains('star') || name.contains('spark')) {
      return const BadgePillStyle(
        backgroundColor: Color(0xFFFCE4EC),
        textColor: Color(0xFFEC407A),
        icon: Icons.electric_bolt_rounded,
      );
    } else if (name.contains('help') || name.contains('assist')) {
      return const BadgePillStyle(
        backgroundColor: Color(0xFFE8F5E9),
        textColor: Color(0xFF66BB6A),
        icon: Icons.handshake_rounded,
      );
    } else if (name.contains('team') || name.contains('player')) {
      return const BadgePillStyle(
        backgroundColor: Color(0xFFE3F2FD),
        textColor: Color(0xFF42A5F5),
        icon: Icons.groups_rounded,
      );
    } else {
      return const BadgePillStyle(
        backgroundColor: Color(0xFFF3E5F5),
        textColor: Color(0xFFAB47BC),
        icon: Icons.star_rounded,
      );
    }
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
