/// "Centralized typography system for consistent text styling across the app."
///
/// Typography Scale (using Inter for body, Outfit for display/headings):
///
/// Display:    48 / bold    — Hero numbers (login brand, big stats)
/// Headline1:  24 / bold    — Secondary headlines (sidebar brand)
/// Headline2:  22 / bold    — Large stat numbers
/// PageTitle:  20 / bold    — All page titles
/// SectionTitle: 16 / w700  — Section headers, panel titles
/// CardTitle:  14 / w600    — Card titles, item names
/// Body:       13 / normal  — Default body text
/// BodyMedium: 13 / w500    — Emphasized body text
/// BodyBold:   13 / w600    — Bold body text, labels
/// Small:      12 / normal  — Secondary info, descriptions
/// SmallBold:  12 / w600    — Small bold text, table headers
/// Caption:    11 / normal  — Timestamps, meta info
/// CaptionBold:11 / w600    — Status badges, tags
/// Tiny:       10 / w600    — Chip labels, badge counts
/// Micro:       9 / bold    — Notification badge counts
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Display & Headlines (Outfit) ────────────────────────────────

  /// 48 / bold — Hero numbers, brand name on login
  static TextStyle display({Color? color}) => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 42 / bold — Large animated numbers (points, stats)
  static TextStyle displayLarge({Color? color}) => GoogleFonts.outfit(
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 28 / bold — Extra large values (budget amounts)
  static TextStyle displayMedium({Color? color}) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 24 / bold — Secondary headlines, sidebar brand
  static TextStyle headline1({Color? color}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 22 / w700 — Large stat numbers, section titles
  static TextStyle headline2({Color? color}) => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 20 / bold — All page titles (consistent everywhere)
  static TextStyle pageTitle({Color? color}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      );

  /// 18 / bold — Sub-section titles, card group headers
  static TextStyle sectionHeader({Color? color}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      );

  // ─── Body & Labels (Inter — inherited from theme) ────────────────

  /// 16 / w700 — Section titles within cards, panel titles
  static TextStyle sectionTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 15 / w600 — Emphasized labels, tab labels
  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 14 / w600 — Card titles, item names, nav items
  static TextStyle cardTitle({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 14 / normal — Regular body text (larger)
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        color: color,
      );

  /// 13 / normal — Default body text
  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        color: color,
      );

  /// 13 / w500 — Slightly emphasized body text
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// 13 / w600 — Bold body text, field labels
  static TextStyle bodyBold({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 12 / normal — Secondary text, descriptions
  static TextStyle small({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        color: color,
      );

  /// 12 / w600 — Small bold text, table headers
  static TextStyle smallBold({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 12 / w500 — Small medium weight text
  static TextStyle smallMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// 11 / normal — Timestamps, meta info, captions
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        color: color,
      );

  /// 11 / w600 — Status badges, tags
  static TextStyle captionBold({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 11 / w700 — Strong emphasis captions
  static TextStyle captionStrong({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// 10 / w600 — Chip labels, tiny badges
  static TextStyle tiny({Color? color}) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// 9 / bold — Notification count badges
  static TextStyle micro({Color? color}) => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: color,
      );

  // ─── Special Purpose ─────────────────────────────────────────────

  /// Emoji display (28pt, no specific font)
  static TextStyle emoji({double size = 28}) => TextStyle(fontSize: size);

  /// Login subtitle (18pt Inter)
  static TextStyle loginSubtitle({Color? color}) => GoogleFonts.inter(
        fontSize: 18,
        color: color,
      );

  /// Tab label styles
  static TextStyle tabSelected({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle tabUnselected({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Navigation sidebar item
  static TextStyle navItem({
    required bool isSelected,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: color,
      );
}
