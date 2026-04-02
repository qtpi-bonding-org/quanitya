import 'package:intl/intl.dart';

/// Standardized date formatting for the app.
///
/// All user-visible dates use biggest-denomination-first numeric ordering
/// (yyyy MM dd), matching the lab-notebook aesthetic.
///
/// Pass [locale] to format dates for a specific locale. If omitted,
/// uses the current default locale.
abstract final class QuanityaDateFormat {
  /// "2026 03 19"
  static String full(DateTime date, [String? locale]) =>
      DateFormat('yyyy MM dd', locale).format(date);

  /// "03 19"
  static String monthDay(DateTime date, [String? locale]) =>
      DateFormat('MM dd', locale).format(date);

  /// "Mar 19" — compact with abbreviated month name
  static String monthDayCompact(DateTime date, [String? locale]) =>
      DateFormat.MMMd(locale).format(date);

  /// "2026 03 19 14:30"
  static String timestamp(DateTime date, [String? locale]) =>
      DateFormat('yyyy MM dd HH:mm', locale).format(date);

  /// "2:30 PM" (en) or "14:30" (es/fr/pt)
  static String time(DateTime date, [String? locale]) =>
      DateFormat.jm(locale).format(date);

  /// "02:30:05" — for ticking clocks
  static String timePrecise(DateTime date, [String? locale]) =>
      DateFormat('HH:mm:ss', locale).format(date);
}
