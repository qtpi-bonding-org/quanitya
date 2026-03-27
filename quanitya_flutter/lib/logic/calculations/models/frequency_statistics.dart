import 'package:freezed_annotation/freezed_annotation.dart';

part 'frequency_statistics.freezed.dart';
part 'frequency_statistics.g.dart';

/// Frequency/cycle analysis for event-based data (e.g., period tracking).
@freezed
abstract class FrequencyStatistics with _$FrequencyStatistics {
  const FrequencyStatistics._();
  const factory FrequencyStatistics({
    /// Number of events analyzed
    required int eventCount,
    /// Average days between consecutive events
    required double averageDaysBetween,
    /// Standard deviation of cycle lengths (regularity indicator)
    required double cycleLengthStdDev,
    /// Individual cycle lengths in days
    required List<int> cycleLengths,
    /// Shortest cycle observed
    required int shortestCycle,
    /// Longest cycle observed
    required int longestCycle,
  }) = _FrequencyStatistics;

  factory FrequencyStatistics.fromJson(Map<String, dynamic> json) =>
      _$FrequencyStatisticsFromJson(json);

  /// Empty statistics for insufficient data.
  factory FrequencyStatistics.empty() => const FrequencyStatistics(
        eventCount: 0,
        averageDaysBetween: 0,
        cycleLengthStdDev: 0,
        cycleLengths: [],
        shortestCycle: 0,
        longestCycle: 0,
      );
}

/// Frequency distribution for categorical or discrete data.
@freezed
abstract class FrequencyDistribution with _$FrequencyDistribution {
  const FrequencyDistribution._();
  const factory FrequencyDistribution({
    /// Map of value to count
    required Map<String, int> frequencies,
    /// Total count
    required int total,
    /// Most frequent value(s)
    required List<String> mode,
    /// Highest frequency count
    required int maxFrequency,
  }) = _FrequencyDistribution;

  factory FrequencyDistribution.fromJson(Map<String, dynamic> json) =>
      _$FrequencyDistributionFromJson(json);
}
