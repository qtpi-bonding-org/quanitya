import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../../templates/enums/field_enum.dart';

part 'field_analysis_context.freezed.dart';
part 'field_analysis_context.g.dart';

/// Context information about a field for AI analysis suggestions
@freezed
abstract class FieldAnalysisContext with _$FieldAnalysisContext {
  const FieldAnalysisContext._();
  const factory FieldAnalysisContext({
    required String fieldId,
    required String fieldName,
    required String fieldTypeString,
    required AnalysisDataType startType,
    required List<String> sampleValues,
    required int dataPointCount,
    String? description,
    Map<String, dynamic>? metadata,
  }) = _FieldAnalysisContext;

  factory FieldAnalysisContext.fromJson(Map<String, dynamic> json) =>
      _$FieldAnalysisContextFromJson(json);
}

extension FieldAnalysisContextExt on FieldAnalysisContext {
  /// Get the actual FieldEnum from the string
  FieldEnum get fieldType {
    return FieldEnum.values.firstWhere(
      (type) => type.name == fieldTypeString,
      orElse: () => FieldEnum.text,
    );
  }

  /// Create context with FieldEnum
  static FieldAnalysisContext create({
    required String fieldId,
    required String fieldName,
    required FieldEnum fieldType,
    required AnalysisDataType startType,
    required List<String> sampleValues,
    required int dataPointCount,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return FieldAnalysisContext(
      fieldId: fieldId,
      fieldName: fieldName,
      fieldTypeString: fieldType.name,
      startType: startType,
      sampleValues: sampleValues,
      dataPointCount: dataPointCount,
      description: description,
      metadata: metadata,
    );
  }
}

/// Context for AI pipeline suggestions
@freezed
abstract class PipelineSuggestionContext with _$PipelineSuggestionContext {
  const PipelineSuggestionContext._();
  const factory PipelineSuggestionContext({
    required FieldAnalysisContext fieldContext,
    required String userIntent,
    required Map<String, dynamic> operationDocs,
    required Map<String, dynamic> examplePipeline,
  }) = _PipelineSuggestionContext;

  factory PipelineSuggestionContext.fromJson(Map<String, dynamic> json) =>
      _$PipelineSuggestionContextFromJson(json);
}