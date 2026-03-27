import 'package:freezed_annotation/freezed_annotation.dart';
import 'field_analysis_context.dart';
import 'matrix_vector_scalar/analysis_data_type.dart';

part 'analysis_input.freezed.dart';

/// Input model for AI analysis script generation.
///
/// This model encapsulates all the parameters needed for analysis script generation,
/// providing type safety and clear structure for the orchestrator.
@freezed
abstract class AnalysisInput with _$AnalysisInput {
  const AnalysisInput._();
  const factory AnalysisInput({
    /// User's natural language description of what they want to analyze
    required String intent,
    
    /// The starting data type for the analysis script
    required AnalysisDataType startType,
    
    /// Context about the field being analyzed (type, characteristics, etc.)
    required FieldAnalysisContext fieldContext,
  }) = _AnalysisInput;
}