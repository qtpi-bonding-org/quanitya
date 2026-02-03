import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/analysis_output_mode.dart';
import 'analysis_enums.dart';

part 'analysis_pipeline.freezed.dart';
part 'analysis_pipeline.g.dart';

@freezed
class AnalysisPipelineModel with _$AnalysisPipelineModel {
  const factory AnalysisPipelineModel({
    required String id,
    required String name,
    required String fieldId,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
    required String snippet,
    String? reasoning,
    String? metadataJson,
    required DateTime updatedAt,
  }) = _AnalysisPipelineModel;

  factory AnalysisPipelineModel.fromJson(Map<String, dynamic> json) =>
      _$AnalysisPipelineModelFromJson(json);
}
