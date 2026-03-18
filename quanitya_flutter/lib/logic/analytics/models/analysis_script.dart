import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/analysis_output_mode.dart';
import 'analysis_enums.dart';

part 'analysis_script.freezed.dart';
part 'analysis_script.g.dart';

@freezed
class AnalysisScriptModel with _$AnalysisScriptModel {
  const factory AnalysisScriptModel({
    required String id,
    required String name,
    required String fieldId,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
    required String snippet,
    String? reasoning,
    String? metadataJson,
    int? entryRangeStart,
    int? entryRangeEnd,
    required DateTime updatedAt,
  }) = _AnalysisScriptModel;

  factory AnalysisScriptModel.fromJson(Map<String, dynamic> json) =>
      _$AnalysisScriptModelFromJson(json);
}
