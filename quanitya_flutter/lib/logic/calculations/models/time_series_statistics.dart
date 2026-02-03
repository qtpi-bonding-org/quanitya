import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_series_statistics.freezed.dart';
part 'time_series_statistics.g.dart';

/// A single point in a time series.
typedef TimeSeriesPoint = ({DateTime date, num value});

/// Rolling average result with date alignment.
@freezed
class RollingAverageResult with _$RollingAverageResult {
  const factory RollingAverageResult({
    required List<({DateTime date, double value})> points,
    required int windowDays,
  }) = _RollingAverageResult;

  factory RollingAverageResult.fromJson(Map<String, dynamic> json) =>
      _$RollingAverageResultFromJson(json);
}

/// Period-over-period comparison.
@freezed
class PeriodComparison with _$PeriodComparison {
  const factory PeriodComparison({
    required double currentPeriodMean,
    required double previousPeriodMean,
    required double absoluteChange,
    required double percentChange,
    required int periodDays,
  }) = _PeriodComparison;

  factory PeriodComparison.fromJson(Map<String, dynamic> json) =>
      _$PeriodComparisonFromJson(json);
}
