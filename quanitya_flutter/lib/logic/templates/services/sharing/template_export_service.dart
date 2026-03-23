import 'dart:convert';
import 'package:injectable/injectable.dart';

import '../../../../infrastructure/core/try_operation.dart';
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
      category: 'uncategorized',
      aesthetics: templateWithAesthetics.aesthetics,
      analysisScripts: analysisScripts,
      description: description?.trim(),
    );

    // Sanitize IDs for clean, readable export
    final sanitized = shareableTemplate.sanitizeForExport();

    // Convert to JSON with pretty formatting
    final jsonMap = sanitized.toJson();
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
        await tryMethod(
          () async {
            final script = await _scriptRepository.getScript(scriptId);
            if (script != null) {
              scripts.add(script);
            }
          },
          (message, [cause]) => Exception(message),
          'loadScript',
        );
      } catch (_) {
        // tryMethod already logged — continue to next script
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
      return await tryMethod(
        () async {
          final scripts =
              await _scriptRepository.getScriptsForField(fieldId);
          return scripts
              .map(
                (p) => AnalysisScriptInfo(
                  id: p.id,
                  name: p.name,
                  description: 'Analysis script for ${p.fieldId}',
                ),
              )
              .toList();
        },
        (message, [cause]) => Exception(message),
        'getAvailableScripts',
      );
    } catch (_) {
      // tryMethod already logged — return empty for UI
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
