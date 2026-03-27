import 'package:freezed_annotation/freezed_annotation.dart';
import 'matrix_vector_scalar/time_series_matrix.dart';

part 'analysis_output.freezed.dart';
// part 'analysis_output.g.dart'; // We parse manually in service for now to avoid generation complexity

/// Strict output model for Analysis Script.
///
/// A script MUST be configured to produce exactly one of these types.
/// The content is always a LIST of that type (e.g. Multi-Scalar, Multi-Vector).
@freezed
abstract class AnalysisOutput with _$AnalysisOutput {
  const AnalysisOutput._();
  /// List of scalar values (e.g. Mean=10, Max=20)
  const factory AnalysisOutput.scalar(List<AnalysisScalar> scalars) =
      _ScalarOutput;

  /// List of simple vectors (e.g. Distribution Histograms)
  const factory AnalysisOutput.vector(List<AnalysisVector> vectors) =
      _VectorOutput;

  /// List of time-series matrices (e.g. Multi-Variate Graphs)
  const factory AnalysisOutput.matrix(List<TimeSeriesMatrix> matrices) =
      _MatrixOutput;
}

/// Simple labeled scalar
@freezed
abstract class AnalysisScalar with _$AnalysisScalar {
  const AnalysisScalar._();
  const factory AnalysisScalar({
    required String label,
    required double value,
    String? unit,
  }) = _AnalysisScalar;
}

/// Simple labeled vector (1D)
@freezed
abstract class AnalysisVector with _$AnalysisVector {
  const AnalysisVector._();
  const factory AnalysisVector({
    required String label,
    required List<double> values,
  }) = _AnalysisVector;
}
