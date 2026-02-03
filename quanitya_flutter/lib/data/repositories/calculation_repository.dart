import 'dart:math' as math;

import 'package:injectable/injectable.dart';

/// Pure math repository for calculation operations.
///
/// All methods operate on primitives only - no MVS types, no models.
/// This enables easy testing and reuse across different contexts.
@injectable
class CalculationRepository {
  const CalculationRepository();

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORICAL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate frequency distribution for categorical values.
  /// Returns: Map<category, count>
  Map<String, int> frequencyDistribution(List<String> values) {
    final frequencies = <String, int>{};
    for (final value in values) {
      frequencies[value] = (frequencies[value] ?? 0) + 1;
    }
    return frequencies;
  }

  /// Get most frequent category from categorical values.
  /// Returns: Most frequent category name, or null if empty.
  String? categoricalMode(List<String> values) {
    if (values.isEmpty) return null;

    final frequencies = frequencyDistribution(values);
    final maxCount = frequencies.values.reduce((a, b) => a > b ? a : b);
    return frequencies.entries.firstWhere((e) => e.value == maxCount).key;
  }

  /// Get unique categories in order of first appearance.
  /// Returns: List of unique category names.
  List<String> uniqueCategories(List<String> values) {
    final seen = <String>{};
    return values.where((v) => seen.add(v)).toList();
  }

  /// Count unique categories.
  /// Returns: Number of unique categories.
  int uniqueCategoryCount(List<String> values) {
    return values.toSet().length;
  }

  /// Get frequency count of most frequent category.
  /// Returns: Count of the mode category.
  int categoricalModeCount(List<String> values) {
    if (values.isEmpty) return 0;

    final frequencies = frequencyDistribution(values);
    return frequencies.values.reduce((a, b) => a > b ? a : b);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CYCLE / TEMPORAL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate cycle lengths between consecutive dates.
  /// Returns: List of days between events.
  List<int> cycleLengths(List<DateTime> dates) {
    if (dates.length < 2) return [];

    final sorted = List<DateTime>.from(dates)..sort();
    final lengths = <int>[];

    for (int i = 1; i < sorted.length; i++) {
      final days = sorted[i].difference(sorted[i - 1]).inDays;
      if (days > 0) lengths.add(days);
    }

    return lengths;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMERIC OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate arithmetic mean.
  double mean(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }

  /// Calculate standard deviation (sample).
  double standardDeviation(List<num> values) {
    if (values.length < 2) return 0.0;

    final avg = mean(values);
    final sumSquaredDiff = values.fold<double>(
      0,
      (sum, v) => sum + math.pow(v - avg, 2),
    );
    return math.sqrt(sumSquaredDiff / (values.length - 1));
  }

  /// Calculate median.
  double median(List<num> values) {
    if (values.isEmpty) return 0.0;

    final sorted = List<num>.from(values)..sort();
    final middle = sorted.length ~/ 2;

    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle].toDouble();
    }
  }

  /// Calculate mode (most frequent value).
  /// Returns null if empty or all values appear once.
  double? mode(List<num> values) {
    if (values.isEmpty) return null;

    final frequencies = <num, int>{};
    for (final value in values) {
      frequencies[value] = (frequencies[value] ?? 0) + 1;
    }

    final maxCount = frequencies.values.reduce((a, b) => a > b ? a : b);
    
    // If all values appear once, there's no mode
    if (maxCount == 1) return null;
    
    return frequencies.entries
        .firstWhere((e) => e.value == maxCount)
        .key
        .toDouble();
  }

  /// Calculate percentile (0-100).
  double percentile(List<num> values, double p) {
    if (values.isEmpty) return 0.0;
    if (p < 0 || p > 100) throw ArgumentError('Percentile must be 0-100');

    final sorted = List<num>.from(values)..sort();
    final index = (p / 100) * (sorted.length - 1);

    if (index == index.floor()) {
      return sorted[index.floor()].toDouble();
    } else {
      final lower = sorted[index.floor()];
      final upper = sorted[index.ceil()];
      return lower + (upper - lower) * (index - index.floor());
    }
  }

  /// Find minimum value.
  double min(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a < b ? a : b).toDouble();
  }

  /// Find maximum value.
  double max(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a > b ? a : b).toDouble();
  }

  /// Calculate sum.
  double sum(List<num> values) {
    if (values.isEmpty) return 0.0;
    return values.fold<double>(0, (a, b) => a + b);
  }

  /// Calculate range (max - min).
  double range(List<num> values) {
    if (values.isEmpty) return 0.0;
    return max(values) - min(values);
  }

  /// Calculate variance (sample).
  double variance(List<num> values) {
    if (values.length < 2) return 0.0;

    final avg = mean(values);
    final sumSquaredDiff = values.fold<double>(
      0,
      (sum, v) => sum + math.pow(v - avg, 2),
    );
    return sumSquaredDiff / (values.length - 1);
  }

  /// Count values.
  int count(List<num> values) {
    return values.length;
  }
}
