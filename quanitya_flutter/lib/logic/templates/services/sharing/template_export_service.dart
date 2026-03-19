import 'dart:convert';
import 'package:injectable/injectable.dart';

import '../../models/shared/shareable_template.dart';
import '../../../analysis/models/analysis_script.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../data/interfaces/analysis_script_interface.dart';

/// Service for exporting templates to shareable JSON format.
///
/// Converts TemplateWithAesthetics + analysis scripts to ShareableTemplate
/// format suitable for sharing via GitHub Gists, repositories, or direct URLs.
@injectable
class TemplateExportService {
  final IAnalysisScriptRepository? _scriptRepository;

  TemplateExportService(this._scriptRepository);

  /// Export a template with optional aesthetics and analysis scripts.
  ///
  /// [templateWithAesthetics] - The template and aesthetics to export
  /// [author] - Author attribution information
  /// [description] - Optional description for the shared template
  /// [includedScriptIds] - Optional list of analysis script IDs to include
  ///
  /// Returns JSON string ready for sharing.
  Future<String> exportTemplate({
    required TemplateWithAesthetics templateWithAesthetics,
    required AuthorCredit author,
    String? description,
    List<String>? includedScriptIds,
  }) async {
    // Load analysis scripts if requested and repository is available
    List<AnalysisScriptModel>? analysisScripts;
    if (includedScriptIds != null &&
        includedScriptIds.isNotEmpty &&
        _scriptRepository != null) {
      analysisScripts = await _loadAnalysisScripts(includedScriptIds);
    }

    // Create shareable template - no sanitization needed, data is already valid
    final shareableTemplate = ShareableTemplate.create(
      author: author,
      template: templateWithAesthetics.template,
      aesthetics: templateWithAesthetics
          .aesthetics, // Always present in TemplateWithAesthetics
      analysisScripts: analysisScripts,
      description: description?.trim(),
    );

    // Convert to JSON with pretty formatting
    final jsonMap = shareableTemplate.toJson();
    return const JsonEncoder.withIndent('  ').convert(jsonMap);
  }

  /// Load analysis scripts by IDs.
  Future<List<AnalysisScriptModel>> _loadAnalysisScripts(
    List<String> scriptIds,
  ) async {
    if (_scriptRepository == null) return [];

    final scripts = <AnalysisScriptModel>[];

    for (final scriptId in scriptIds) {
      try {
        final script = await _scriptRepository.getScript(scriptId);
        if (script != null) {
          scripts.add(script);
        }
      } catch (e) {
        // Skip invalid scripts, don't fail the entire export
        continue;
      }
    }

    return scripts;
  }

  /// Get available analysis scripts for a template.
  ///
  /// Returns list of script IDs and names for selection UI.
  Future<List<AnalysisScriptInfo>> getAvailableScripts(
    String fieldId,
  ) async {
    if (_scriptRepository == null) return [];

    try {
      final scripts = await _scriptRepository.getScriptsForField(fieldId);
      return scripts
          .map(
            (p) => AnalysisScriptInfo(
              id: p.id,
              name: p.name,
              description: 'Analysis script for ${p.fieldId}',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Information about an available analysis script for export selection.
class AnalysisScriptInfo {
  final String id;
  final String name;
  final String? description;

  const AnalysisScriptInfo({
    required this.id,
    required this.name,
    this.description,
  });
}
