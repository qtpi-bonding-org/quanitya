import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for formatting RRULE strings into human-readable text.
/// 
/// Parses common RRULE patterns and returns friendly descriptions like:
/// - "Daily at 9:00 AM"
/// - "Weekly on Mon, Wed, Fri at 6:00 PM"
/// - "Monthly on the 1st at 10:00 AM"
class RecurrenceFormatter {
  RecurrenceFormatter._();

  /// Format an RRULE string into human-readable text.
  static String format(String rrule) {
    try {
      final parts = _parseRRule(rrule);
      return _buildDescription(parts);
    } catch (e) {
      // Fallback to raw rule if parsing fails
      return rrule;
    }
  }

  /// Parse RRULE string into a map of components
  static Map<String, String> _parseRRule(String rrule) {
    final parts = <String, String>{};
    
    // Remove RRULE: prefix if present
    final cleanRule = rrule.replaceFirst(RegExp(r'^RRULE:', caseSensitive: false), '');
    
    for (final part in cleanRule.split(';')) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        parts[keyValue[0].toUpperCase()] = keyValue[1];
      }
    }
    
    return parts;
  }

  /// Build human-readable description from parsed parts
  static String _buildDescription(Map<String, String> parts) {
    final freq = parts['FREQ']?.toUpperCase();
    final byDay = parts['BYDAY'];
    final byHour = parts['BYHOUR'];
    final byMinute = parts['BYMINUTE'];
    final byMonthDay = parts['BYMONTHDAY'];
    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;

    // Build time string
    String timeStr = '';
    if (byHour != null) {
      final hour = int.tryParse(byHour) ?? 0;
      final minute = int.tryParse(byMinute ?? '0') ?? 0;
      final time = TimeOfDay(hour: hour, minute: minute);
      timeStr = _formatTime(time);
    }

    // Build frequency description
    switch (freq) {
      case 'DAILY':
        if (interval == 1) {
          return timeStr.isNotEmpty ? 'Daily at $timeStr' : 'Daily';
        } else {
          return timeStr.isNotEmpty 
              ? 'Every $interval days at $timeStr' 
              : 'Every $interval days';
        }

      case 'WEEKLY':
        final days = _formatDays(byDay);
        if (interval == 1) {
          if (days.isNotEmpty) {
            return timeStr.isNotEmpty 
                ? 'Weekly on $days at $timeStr' 
                : 'Weekly on $days';
          }
          return timeStr.isNotEmpty ? 'Weekly at $timeStr' : 'Weekly';
        } else {
          if (days.isNotEmpty) {
            return timeStr.isNotEmpty 
                ? 'Every $interval weeks on $days at $timeStr' 
                : 'Every $interval weeks on $days';
          }
          return timeStr.isNotEmpty 
              ? 'Every $interval weeks at $timeStr' 
              : 'Every $interval weeks';
        }

      case 'MONTHLY':
        final dayOfMonth = byMonthDay != null ? _formatOrdinal(int.tryParse(byMonthDay) ?? 1) : '';
        if (interval == 1) {
          if (dayOfMonth.isNotEmpty) {
            return timeStr.isNotEmpty 
                ? 'Monthly on the $dayOfMonth at $timeStr' 
                : 'Monthly on the $dayOfMonth';
          }
          return timeStr.isNotEmpty ? 'Monthly at $timeStr' : 'Monthly';
        } else {
          if (dayOfMonth.isNotEmpty) {
            return timeStr.isNotEmpty 
                ? 'Every $interval months on the $dayOfMonth at $timeStr' 
                : 'Every $interval months on the $dayOfMonth';
          }
          return timeStr.isNotEmpty 
              ? 'Every $interval months at $timeStr' 
              : 'Every $interval months';
        }

      case 'YEARLY':
        if (interval == 1) {
          return timeStr.isNotEmpty ? 'Yearly at $timeStr' : 'Yearly';
        } else {
          return timeStr.isNotEmpty 
              ? 'Every $interval years at $timeStr' 
              : 'Every $interval years';
        }

      default:
        return 'Custom schedule';
    }
  }

  /// Format TimeOfDay to string like "9:00 AM"
  static String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  /// Format BYDAY value to readable string
  /// e.g., "MO,WE,FR" -> "Mon, Wed, Fri"
  static String _formatDays(String? byDay) {
    if (byDay == null || byDay.isEmpty) return '';

    const dayMap = {
      'MO': 'Mon',
      'TU': 'Tue',
      'WE': 'Wed',
      'TH': 'Thu',
      'FR': 'Fri',
      'SA': 'Sat',
      'SU': 'Sun',
    };

    final days = byDay.split(',').map((d) {
      // Handle cases like "1MO" (first Monday)
      final cleanDay = d.replaceAll(RegExp(r'[0-9-]'), '').toUpperCase();
      return dayMap[cleanDay] ?? d;
    }).toList();

    return days.join(', ');
  }

  /// Format number as ordinal (1st, 2nd, 3rd, etc.)
  static String _formatOrdinal(int n) {
    if (n >= 11 && n <= 13) {
      return '${n}th';
    }
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
