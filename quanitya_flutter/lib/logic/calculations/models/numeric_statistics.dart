import 'package:freezed_annotation/freezed_annotation.dart';

part 'numeric_statistics.freezed.dart';
part 'numeric_statistics.g.dart';

/// Complete descriptive statistics for a numeric dataset.
@freezed
abstract class NumericStatistics with _$NumericStatistics {
  const NumericStatistics._();
  const factory NumericStatistics({
    required int count,
    required double sum,
    required double mean,
    required double median,
    required List<num> mode,
    required double min,
    required double max,
    required double range,
    required double standardDeviation,
    required double variance,
    /// 25th percentile (Q1)
    required double percentile25,
    /// 75th percentile (Q3)
    required double percentile75,
    /// Interquartile range (Q3 - Q1)
    required double iqr,
  }) = _NumericStatistics;

  factory NumericStatistics.fromJson(Map<String, dynamic> json) =>
      _$NumericStatisticsFromJson(json);

  /// Empty statistics for when there's no data.
  factory NumericStatistics.empty() => const NumericStatistics(
        count: 0,
        sum: 0,
        mean: 0,
        median: 0,
        mode: [],
        min: 0,
        max: 0,
        range: 0,
        standardDeviation: 0,
        variance: 0,
        percentile25: 0,
        percentile75: 0,
        iqr: 0,
      );
}
