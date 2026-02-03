import 'dart:convert';
import 'package:injectable/injectable.dart';

import '../../models/shared/shareable_template.dart';
import '../../../analytics/models/analysis_pipeline.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../data/interfaces/analysis_pipeline_interface.dart';

/// Service for exporting templates to shareable JSON format.
///
/// Converts TemplateWithAesthetics + analysis pipelines to ShareableTemplate
/// format suitable for sharing via GitHub Gists, repositories, or direct URLs.
@injectable
class TemplateExportService {
  final IAnalysisPipelineRepository? _pipelineRepository;

  TemplateExportService(this._pipelineRepository);

  /// Export a template with optional aesthetics and analysis pipelines.
  ///
  /// [templateWithAesthetics] - The template and aesthetics to export
  /// [author] - Author attribution information
  /// [description] - Optional description for the shared template
  /// [includedPipelineIds] - Optional list of analysis pipeline IDs to include
  ///
  /// Returns JSON string ready for sharing.
  Future<String> exportTemplate({
    required TemplateWithAesthetics templateWithAesthetics,
    required AuthorCredit author,
    String? description,
    List<String>? includedPipelineIds,
  }) async {
    // Load analysis pipelines if requested and repository is available
    List<AnalysisPipelineModel>? analysisPipelines;
    if (includedPipelineIds != null &&
        includedPipelineIds.isNotEmpty &&
        _pipelineRepository != null) {
      analysisPipelines = await _loadAnalysisPipelines(includedPipelineIds);
    }

    // Create shareable template - no sanitization needed, data is already valid
    final shareableTemplate = ShareableTemplate.create(
      author: author,
      template: templateWithAesthetics.template,
      aesthetics: templateWithAesthetics
          .aesthetics, // Always present in TemplateWithAesthetics
      analysisPipelines: analysisPipelines,
      description: description?.trim(),
    );

    // Convert to JSON with pretty formatting
    final jsonMap = shareableTemplate.toJson();
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }

  /// Load analysis pipelines by IDs.
  Future<List<AnalysisPipelineModel>> _loadAnalysisPipelines(
    List<String> pipelineIds,
  ) async {
    if (_pipelineRepository == null) return [];

    final pipelines = <AnalysisPipelineModel>[];

    for (final pipelineId in pipelineIds) {
      try {
        final pipeline = await _pipelineRepository.getPipeline(pipelineId);
        if (pipeline != null) {
          pipelines.add(pipeline);
        }
      } catch (e) {
        // Skip invalid pipelines, don't fail the entire export
        continue;
      }
    }

    return pipelines;
  }

  /// Get available analysis pipelines for a template.
  ///
  /// Returns list of pipeline IDs and names for selection UI.
  Future<List<AnalysisPipelineInfo>> getAvailablePipelines(
    String fieldId,
  ) async {
    if (_pipelineRepository == null) return [];

    try {
      final pipelines = await _pipelineRepository.getPipelinesForField(fieldId);
      return pipelines
          .map(
            (p) => AnalysisPipelineInfo(
              id: p.id,
              name: p.name,
              description: 'Analysis pipeline for ${p.fieldId}',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Information about an available analysis pipeline for export selection.
class AnalysisPipelineInfo {
  final String id;
  final String name;
  final String? description;

  const AnalysisPipelineInfo({
    required this.id,
    required this.name,
    this.description,
  });
}
