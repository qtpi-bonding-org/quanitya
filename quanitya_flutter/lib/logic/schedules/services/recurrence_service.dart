import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rrule/rrule.dart';


/// Service for parsing and calculating recurrence rules (RRULE).
/// 
/// Wraps the `rrule` package to provide a clean interface for:
/// - Parsing RRULE strings
/// - Generating occurrence dates
/// - Human-readable descriptions
/// - Validation
@lazySingleton
class RecurrenceService {
  
  /// Try to parse an RRULE string. Returns null if invalid.
  RecurrenceRule? tryParse(String rruleString) {
    try {
      return RecurrenceRule.fromString(rruleString);
    } catch (e) {
      debugPrint('RecurrenceService: Invalid RRULE "$rruleString": $e');
      return null;
    }
  }

  /// Check if an RRULE string is valid.
  bool isValid(String rruleString) {
    return tryParse(rruleString) != null;
  }

  /// Get occurrences of a recurrence rule within a date range.
  /// 
  /// [rruleString] - The RRULE string (e.g., "FREQ=DAILY;BYHOUR=9")
  /// [start] - The start date for the recurrence (DTSTART equivalent)
  /// [after] - Only return occurrences after this date (exclusive)
  /// [before] - Only return occurrences before this date (exclusive)
  /// 
  /// Returns empty list if RRULE is invalid.
  List<DateTime> getOccurrences({
    required String rruleString,
    required DateTime start,
    DateTime? after,
    DateTime? before,
  }) {
    final rule = tryParse(rruleString);
    if (rule == null) return [];

    try {
      return rule.getInstances(
        start: start,
        after: after,
        before: before,
      ).toList();
    } catch (e) {
      debugPrint('RecurrenceService: Error getting occurrences: $e');
      return [];
    }
  }

  /// Get the next N occurrences from a start date.
  List<DateTime> getNextOccurrences({
    required String rruleString,
    required DateTime start,
    required int count,
    DateTime? after,
  }) {
    final rule = tryParse(rruleString);
    if (rule == null) return [];

    try {
      return rule.getInstances(
        start: start,
        after: after,
      ).take(count).toList();
    } catch (e) {
      debugPrint('RecurrenceService: Error getting next occurrences: $e');
      return [];
    }
  }

  /// Convert RRULE to human-readable text.
  /// 
  /// Returns the raw RRULE string if conversion fails.
  String toHumanReadable(String rruleString) {
    final rule = tryParse(rruleString);
    if (rule == null) return rruleString;

    try {
      // NOTE: Rrule.toText() requires l10n, which is causing build issues 
      // due to missing exports in version 0.2.17.
      // We will temporarily return the raw string or a basic description 
      // until the dependency is sorted.
      return 'Repeats ${rule.frequency.toString().split('.').last}';
    } catch (e) {
      debugPrint('RecurrenceService: Error converting to text: $e');
      return rruleString;
    }
  }

  /// Get the frequency of a rule (daily, weekly, monthly, yearly).
  Frequency? getFrequency(String rruleString) {
    return tryParse(rruleString)?.frequency;
  }
}


