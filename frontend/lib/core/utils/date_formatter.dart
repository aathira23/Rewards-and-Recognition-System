import 'package:intl/intl.dart';

/// A centralized utility for consistent date formatting across the application.
class AppDateFormatter {
  /// e.g. 20 Oct 2023
  static String short(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// e.g. 20 Oct 2023, 14:30
  static String dateTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  /// e.g. Friday, 20 Oct 2023
  static String full(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('EEEE, d MMM yyyy').format(date);
  }

  /// e.g. 2023-10-20 (Standard API format)
  static String api(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// e.g. October 2023
  static String monthYear(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Parse a date string from the API
  static DateTime? parse(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Format a dynamic date (String or DateTime) to short format
  static String format(dynamic date) {
    if (date == null) return '—';
    if (date is DateTime) return short(date);
    if (date is String) {
      final parsed = parse(date);
      return parsed != null ? short(parsed) : date;
    }
    return '—';
  }

  /// e.g. 14:30
  static String formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final parsed = parse(dateStr);
    if (parsed == null) return '—';
    return DateFormat('HH:mm').format(parsed);
  }
}
