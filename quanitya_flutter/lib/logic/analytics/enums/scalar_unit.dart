import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';

/// Special scalar units that the UI auto-formats.
///
/// Scripts return these as the `unit` string in scalar output.
/// The ScalarCard recognizes them and formats the value accordingly
/// instead of showing the raw double + unit label.
///
/// Any unit string not matching these is displayed as-is below the value.
enum ScalarUnit {
  /// Epoch milliseconds → "MMM d" (e.g. "Apr 5")
  timestamp('timestamp'),

  /// Epoch milliseconds → "MMM d, HH:mm" (e.g. "Apr 5, 12:00")
  timestampFull('timestamp_full'),

  /// 0–1 float → "73.0%" (e.g. 0.73 → "73.0%")
  percentage('percentage'),

  /// Minutes → "2h 30m" or "45m" (e.g. 150 → "2h 30m")
  duration('duration');

  /// The string scripts use in `{ unit: '...' }`.
  final String key;

  const ScalarUnit(this.key);

  /// Look up by key string. Returns null if not a special unit.
  static ScalarUnit? fromKey(String? key) {
    if (key == null) return null;
    for (final u in values) {
      if (u.key == key) return u;
    }
    return null;
  }

  /// Format a raw double value according to this unit's rules.
  String format(double value) {
    return switch (this) {
      ScalarUnit.timestamp => QuanityaDateFormat.monthDay(
          DateTime.fromMillisecondsSinceEpoch(value.toInt()),
        ),
      ScalarUnit.timestampFull => QuanityaDateFormat.timestamp(
          DateTime.fromMillisecondsSinceEpoch(value.toInt()),
        ),
      ScalarUnit.percentage => '${(value * 100).toStringAsFixed(1)}%',
      ScalarUnit.duration => _formatDuration(value),
    };
  }

  static String _formatDuration(double value) {
    final totalMinutes = value.round();
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
