/// "Global theme configuration for the application, defining light and dark mode styles."
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color brandBlue = Color(0xFF1E56BD);
  static const Color brandSecondary = Color(0xFF15439D);

  // Surface Colors - Light
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF8F9FA);

  // Surface Colors - Dark
  static const Color darkSurface = Color(0xFF1A1C1E);
  static const Color darkBackground = Color(0xFF111315);
  static const Color darkCard = Color(0xFF222529);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        primary: brandBlue,
        secondary: brandSecondary,
        surface: surfaceWhite,
        surfaceContainer: backgroundGrey,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      inputDecorationTheme:
          _inputDecoration(brandBlue, const Color(0xFFE0E0E0)),
      elevatedButtonTheme: _elevatedButtonTheme(brandBlue, surfaceWhite),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        primary: brandBlue,
        secondary: brandBlue.withValues(alpha: 0.8),
        surface: darkSurface,
        surfaceContainer: darkBackground,
        brightness: Brightness.dark,
      ).copyWith(
        surface: darkSurface,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      inputDecorationTheme: _inputDecoration(brandBlue, Colors.white24),
      elevatedButtonTheme: _elevatedButtonTheme(brandBlue, Colors.white),
    );
  }

  static InputDecorationTheme _inputDecoration(Color primary, Color border) {
    return InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg, Color fg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
