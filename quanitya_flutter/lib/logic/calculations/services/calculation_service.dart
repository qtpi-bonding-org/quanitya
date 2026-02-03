import 'package:injectable/injectable.dart';

import '../../../data/repositories/calculation_repository.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../analytics/enums/calculation.dart';
import '../../analytics/models/matrix_vector_scalar/mvs_union.dart';
import '../../analytics/models/matrix_vector_scalar/time_series_matrix.dart';
import '../../analytics/models/matrix_vector_scalar/value_vector.dart';
import '../../analytics/models/matrix_vector_scalar/stat_scalar.dart';
import '../../analytics/models/matrix_vector_scalar/category_vector.dart';
import '../../analytics/models/matrix_vector_scalar/timestamp_vector.dart';
import '../../analytics/exceptions/analysis_exceptions.dart';

/// MVS-packaging service for calculation operations.
///
/// Wraps pure math from CalculationRepository into MVS types.
/// This enables composable pipeline operations.
///
/// Architecture:
/// - CalculationRepository: Pure math (primitives → primitives)
/// - CalculationService: MVS packaging (primitives → MVS types)
/// - AnalysisEngine: Pipeline orchestration (MVS → MVS)
@lazySingleton
class CalculationService {
  final CalculationRepository _calc;

  const CalculationService(this._calc);

  // ═══════════════════════════════════════════════════════════════════════════
  // MVS PACKAGING HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Package single numeric result into MVS StatScalar.
  MvsUnion scalarToMvs(double value) {
    return MvsUnion.statScalar(StatScalar(value));
  }

  /// Package numeric list into MVS ValueVector.
  MvsUnion valuesToMvs(List<num> values) {
    return MvsUnion.valueVector(ValueVector(values));
  }

  /// Package string list into MVS CategoryVector.
  MvsUnion categoriesToMvs(List<String> categories) {
    return MvsUnion.categoryVector(CategoryVector(categories));
  }

  /// Package date list into MVS TimestampVector.
  MvsUnion datesToMvs(List<DateTime> dates) {
    return MvsUnion.timestampVector(TimestampVector(dates));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORICAL OPERATIONS → MVS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Package frequency distribution into MVS ValueVector.
  /// Input: List<String> categories
  /// Output: ValueVector with frequency counts (in order of first appearance)
  MvsUnion frequencyDistributionToMvs(List<String> values) {
    final frequencies = _calc.frequencyDistribution(values);

    if (frequencies.isEmpty) {
      return MvsUnion.valueVector(const ValueVector([]));
    }

    // Get unique categories in order of first appearance
    final uniqueCategories = _calc.uniqueCategories(values);

    // Map frequencies to counts in category order
    final counts = uniqueCategories
        .map((cat) => frequencies[cat]?.toDouble() ?? 0.0)
        .toList();

    return MvsUnion.valueVector(ValueVector(counts));
  }

  /// Calculate category mode (most frequent count) and return as MVS StatScalar.
  MvsUnion categoryModeToMvs(List<String> values) {
    final count = _calc.categoricalModeCount(values);
    return scalarToMvs(count.toDouble());
  }

  /// Calculate unique category count and return as MVS StatScalar.
  MvsUnion categoryUniqueCountToMvs(List<String> values) {
    final count = _calc.uniqueCategoryCount(values);
    return scalarToMvs(count.toDouble());
  }

  /// Get unique categories as MVS CategoryVector.
  MvsUnion uniqueCategoriesToMvs(List<String> values) {
    final unique = _calc.uniqueCategories(values);
    return categoriesToMvs(unique);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CYCLE / TEMPORAL OPERATIONS → MVS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Package cycle lengths into MVS ValueVector.
  /// Input: List<DateTime> event dates
  /// Output: ValueVector with cycle lengths in days
  MvsUnion cycleLengthsToMvs(List<DateTime> eventDates) {
    final lengths = _calc.cycleLengths(eventDates);
    final lengthsDouble = lengths.map((l) => l.toDouble()).toList();

    return MvsUnion.valueVector(ValueVector(lengthsDouble));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMERIC OPERATIONS → MVS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate mean and return as MVS StatScalar.
  MvsUnion meanToMvs(List<num> values) {
    final result = _calc.mean(values);
    return scalarToMvs(result);
  }

  /// Calculate median and return as MVS StatScalar.
  MvsUnion medianToMvs(List<num> values) {
    final result = _calc.median(values);
    return scalarToMvs(result);
  }

  /// Calculate mode and return as MVS StatScalar.
  MvsUnion modeToMvs(List<num> values) {
    final result = _calc.mode(values) ?? 0.0;
    return scalarToMvs(result);
  }

  /// Calculate standard deviation and return as MVS StatScalar.
  MvsUnion standardDeviationToMvs(List<num> values) {
    final result = _calc.standardDeviation(values);
    return scalarToMvs(result);
  }

  /// Calculate variance and return as MVS StatScalar.
  MvsUnion varianceToMvs(List<num> values) {
    final result = _calc.variance(values);
    return scalarToMvs(result);
  }

  /// Calculate min and return as MVS StatScalar.
  MvsUnion minToMvs(List<num> values) {
    final result = _calc.min(values);
    return scalarToMvs(result);
  }

  /// Calculate max and return as MVS StatScalar.
  MvsUnion maxToMvs(List<num> values) {
    final result = _calc.max(values);
    return scalarToMvs(result);
  }

  /// Calculate sum and return as MVS StatScalar.
  MvsUnion sumToMvs(List<num> values) {
    final result = _calc.sum(values);
    return scalarToMvs(result);
  }

  /// Calculate range and return as MVS StatScalar.
  MvsUnion rangeToMvs(List<num> values) {
    final result = _calc.range(values);
    return scalarToMvs(result);
  }

  /// Calculate percentile and return as MVS StatScalar.
  MvsUnion percentileToMvs(List<num> values, double percentile) {
    final result = _calc.percentile(values, percentile);
    return scalarToMvs(result);
  }

  /// Calculate count and return as MVS StatScalar.
  MvsUnion countToMvs(List<num> values) {
    final result = _calc.count(values);
    return scalarToMvs(result.toDouble());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIRECT REPOSITORY ACCESS (for non-MVS use cases)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Direct access to pure math operations.
  /// Use when you need primitives, not MVS types.
  CalculationRepository get repository => _calc;

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPATIBILITY (delegate to repository)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate the arithmetic mean.
  double mean(List<num> values) => _calc.mean(values);

  /// Calculate the median (middle value).
  double median(List<num> values) => _calc.median(values);

  /// Calculate the mode (most frequent value).
  List<num> mode(List<num> values) {
    final result = _calc.mode(values);
    return result != null ? [result] : [];
  }

  /// Calculate population standard deviation.
  double standardDeviation(List<num> values) => _calc.standardDeviation(values);

  /// Calculate population variance.
  double variance(List<num> values) => _calc.variance(values);

  /// Calculate a specific percentile (0-100).
  double percentile(List<num> values, double p) => _calc.percentile(values, p);

  // ═══════════════════════════════════════════════════════════════════════════
  // PIPELINE EXECUTION DISPATCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Execute a calculation operation on MVS input.
  ///
  /// Dispatches to the appropriate method based on the Calculation enum.
  /// Used by PipelineExecutor for step execution.
  Future<MvsUnion> execute(
    Calculation function,
    MvsUnion input,
    Map<String, dynamic> params,
  ) {
    return tryMethod(
      () async {
        return switch (function) {
          // === MATRIX EXTRACTORS ===
          Calculation.extractField => _executeExtractField(input, params),
          Calculation.extractTimestamps => _executeExtractTimestamps(input),

          // === MATRIX TRANSFORMERS ===
          Calculation.matrixRollingAverage =>
            _executeMatrixRollingAverage(input, params),
          Calculation.matrixFilter => _executeMatrixFilter(input, params),

          // === VALUE VECTOR AGGREGATORS ===
          Calculation.vectorMean => meanToMvs(input.asValueVector.values),
          Calculation.vectorMedian => medianToMvs(input.asValueVector.values),
          Calculation.vectorMode => modeToMvs(input.asValueVector.values),
          Calculation.vectorStandardDev =>
            standardDeviationToMvs(input.asValueVector.values),
          Calculation.vectorVariance => varianceToMvs(input.asValueVector.values),
          Calculation.vectorMin => minToMvs(input.asValueVector.values),
          Calculation.vectorMax => maxToMvs(input.asValueVector.values),
          Calculation.vectorSum => sumToMvs(input.asValueVector.values),
          Calculation.vectorRange => rangeToMvs(input.asValueVector.values),
          Calculation.vectorPercentile => percentileToMvs(
              input.asValueVector.values,
              (params['percentile'] as num).toDouble(),
            ),
          Calculation.vectorFirst => _executeVectorFirst(input),
          Calculation.vectorLast => _executeVectorLast(input),
          Calculation.vectorCount => countToMvs(input.asValueVector.values),

          // === VALUE VECTOR TRANSFORMERS ===
          Calculation.vectorAbs => _executeVectorAbs(input),
          Calculation.vectorDifference => _executeVectorDifference(input),
          Calculation.vectorPercentChange => _executeVectorPercentChange(input),

          // === TIMESTAMP VECTOR ANALYZERS ===
          Calculation.dayOfWeek => _executeDayOfWeek(input),
          Calculation.hourOfDay => _executeHourOfDay(input),
          Calculation.dayOfMonth => _executeDayOfMonth(input),
          Calculation.monthOfYear => _executeMonthOfYear(input),
          Calculation.calculateIntervals => _executeCalculateIntervals(input),

          // === TIMESTAMP VECTOR AGGREGATORS ===
          Calculation.timeSpanDays => _executeTimeSpanDays(input),
          Calculation.averageInterval => _executeAverageInterval(input),

          // === CATEGORICAL EXTRACTORS ===
          Calculation.extractCategoricalField =>
            _executeExtractCategoricalField(input, params),

          // === CATEGORICAL AGGREGATORS ===
          Calculation.categoryMode =>
            categoryModeToMvs(input.asCategoryVector.values),
          Calculation.categoryFrequencies =>
            frequencyDistributionToMvs(input.asCategoryVector.values),
          Calculation.categoryUnique =>
            categoryUniqueCountToMvs(input.asCategoryVector.values),

          // === CATEGORICAL TRANSFORMERS ===
          Calculation.categoryFilter => _executeCategoryFilter(input, params),
          Calculation.categoryMap => _executeCategoryMap(input, params),

          // === SCALAR COMBINERS (handled by PipelineExecutor) ===
          Calculation.scalarAdd ||
          Calculation.scalarSubtract ||
          Calculation.scalarMultiply ||
          Calculation.scalarDivide =>
            throw AnalysisException(
              'Scalar combiners must be executed via PipelineExecutor',
            ),
        };
      },
      AnalysisException.new,
      'execute',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE EXECUTION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  MvsUnion _executeExtractField(MvsUnion input, Map<String, dynamic> params) {
    final matrix = input.asTimeSeriesMatrix;
    final fieldName = params['fieldName'] as String;
    final values = matrix.getColumnByName(fieldName);
    return MvsUnion.valueVector(values);
  }

  MvsUnion _executeExtractTimestamps(MvsUnion input) {
    final matrix = input.asTimeSeriesMatrix;
    return MvsUnion.timestampVector(matrix.timestampVector);
  }

  MvsUnion _executeMatrixRollingAverage(
    MvsUnion input,
    Map<String, dynamic> params,
  ) {
    // TODO: Implement rolling average on matrix
    throw AnalysisException('matrixRollingAverage not yet implemented');
  }

  MvsUnion _executeMatrixFilter(MvsUnion input, Map<String, dynamic> params) {
    // TODO: Implement matrix filtering
    throw AnalysisException('matrixFilter not yet implemented');
  }

  MvsUnion _executeVectorFirst(MvsUnion input) {
    final values = input.asValueVector.values;
    if (values.isEmpty) {
      throw AnalysisException('Cannot get first value of empty vector');
    }
    return scalarToMvs(values.first.toDouble());
  }

  MvsUnion _executeVectorLast(MvsUnion input) {
    final values = input.asValueVector.values;
    if (values.isEmpty) {
      throw AnalysisException('Cannot get last value of empty vector');
    }
    return scalarToMvs(values.last.toDouble());
  }

  MvsUnion _executeVectorAbs(MvsUnion input) {
    final values = input.asValueVector.values;
    final absValues = values.map((v) => v.abs()).toList();
    return MvsUnion.valueVector(ValueVector(absValues));
  }

  MvsUnion _executeVectorDifference(MvsUnion input) {
    final values = input.asValueVector.values;
    if (values.length < 2) {
      return MvsUnion.valueVector(const ValueVector([]));
    }
    final diffs = <num>[];
    for (int i = 1; i < values.length; i++) {
      diffs.add(values[i] - values[i - 1]);
    }
    return MvsUnion.valueVector(ValueVector(diffs));
  }

  MvsUnion _executeVectorPercentChange(MvsUnion input) {
    final values = input.asValueVector.values;
    if (values.length < 2) {
      return MvsUnion.valueVector(const ValueVector([]));
    }
    final changes = <num>[];
    for (int i = 1; i < values.length; i++) {
      final prev = values[i - 1];
      if (prev != 0) {
        changes.add((values[i] - prev) / prev * 100);
      } else {
        changes.add(0);
      }
    }
    return MvsUnion.valueVector(ValueVector(changes));
  }

  MvsUnion _executeDayOfWeek(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    final days = timestamps.map((t) => t.weekday.toDouble()).toList();
    return MvsUnion.valueVector(ValueVector(days));
  }

  MvsUnion _executeHourOfDay(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    final hours = timestamps.map((t) => t.hour.toDouble()).toList();
    return MvsUnion.valueVector(ValueVector(hours));
  }

  MvsUnion _executeDayOfMonth(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    final days = timestamps.map((t) => t.day.toDouble()).toList();
    return MvsUnion.valueVector(ValueVector(days));
  }

  MvsUnion _executeMonthOfYear(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    final months = timestamps.map((t) => t.month.toDouble()).toList();
    return MvsUnion.valueVector(ValueVector(months));
  }

  MvsUnion _executeCalculateIntervals(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    if (timestamps.length < 2) {
      return MvsUnion.valueVector(const ValueVector([]));
    }
    final intervals = <num>[];
    for (int i = 1; i < timestamps.length; i++) {
      final diff = timestamps[i].difference(timestamps[i - 1]);
      intervals.add(diff.inHours / 24.0); // Convert to days
    }
    return MvsUnion.valueVector(ValueVector(intervals));
  }

  MvsUnion _executeTimeSpanDays(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    if (timestamps.length < 2) {
      return scalarToMvs(0);
    }
    final first = timestamps.first;
    final last = timestamps.last;
    final diff = last.difference(first);
    return scalarToMvs(diff.inHours / 24.0);
  }

  MvsUnion _executeAverageInterval(MvsUnion input) {
    final timestamps = input.asTimestampVector.timestamps;
    if (timestamps.length < 2) {
      return scalarToMvs(0);
    }
    final intervals = <double>[];
    for (int i = 1; i < timestamps.length; i++) {
      final diff = timestamps[i].difference(timestamps[i - 1]);
      intervals.add(diff.inMinutes / 60.0); // Convert to hours
    }
    return scalarToMvs(_calc.mean(intervals));
  }

  MvsUnion _executeExtractCategoricalField(
    MvsUnion input,
    Map<String, dynamic> params,
  ) {
    final matrix = input.asTimeSeriesMatrix;
    final fieldName = params['fieldName'] as String;
    final categories = matrix.getCategoricalField(fieldName);
    return MvsUnion.categoryVector(categories);
  }

  MvsUnion _executeCategoryFilter(MvsUnion input, Map<String, dynamic> params) {
    final categories = input.asCategoryVector.values;
    final filterCategory = params['category'] as String;
    final filtered =
        categories.where((c) => c == filterCategory).toList();
    return MvsUnion.categoryVector(CategoryVector(filtered));
  }

  MvsUnion _executeCategoryMap(MvsUnion input, Map<String, dynamic> params) {
    final categories = input.asCategoryVector.values;
    final mapping = params['mapping'] as Map<String, String>;
    final mapped = categories.map((c) => mapping[c] ?? c).toList();
    return MvsUnion.categoryVector(CategoryVector(mapped));
  }
}
