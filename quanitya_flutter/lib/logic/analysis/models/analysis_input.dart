import 'package:freezed_annotation/freezed_annotation.dart';
import 'matrix_vector_scalar/analysis_data_type.dart';

part 'analysis_input.freezed.dart';

/// Input model for AI analysis script generation.
@freezed
abstract class AnalysisInput with _$AnalysisInput {
  const AnalysisInput._();
  const factory AnalysisInput({
    /// User's natural language description of what they want to analyze
    required String intent,

    /// The starting data type for the analysis script
    required AnalysisDataType startType,
  }) = _AnalysisInput;
}
