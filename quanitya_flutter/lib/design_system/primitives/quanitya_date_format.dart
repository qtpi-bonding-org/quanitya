import 'package:intl/intl.dart';

/// Standardized date formatting for the app.
///
/// All user-visible dates use biggest-denomination-first numeric ordering
/// (yyyy MM dd), matching the lab-notebook aesthetic.
abstract final class QuanityaDateFormat {
  static final _full = DateFormat('yyyy MM dd');
  static final _monthDay = DateFormat('MM dd');
  static final _monthDayCompact = DateFormat('MM/dd');
  static final _timestamp = DateFormat('yyyy MM dd HH:mm');
  static final _time = DateFormat('h:mm a');
  static final _timePrecise = DateFormat('hh:mm:ss');

  /// "2026 03 19"
  static String full(DateTime date) => _full.format(date);

  /// "03 19"
  static String monthDay(DateTime date) => _monthDay.format(date);

  /// "03/19" — compact for chart axis labels
  static String monthDayCompact(DateTime date) => _monthDayCompact.format(date);

  /// "2026 03 19 14:30"
  static String timestamp(DateTime date) => _timestamp.format(date);

  /// "2:30 PM"
  static String time(DateTime date) => _time.format(date);

  /// "02:30:05" — for ticking clocks
  static String timePrecise(DateTime date) => _timePrecise.format(date);
}
