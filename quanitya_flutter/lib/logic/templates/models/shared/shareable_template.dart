import 'package:freezed_annotation/freezed_annotation.dart';
import 'template_field.dart';
import 'tracker_template.dart';
import 'template_aesthetics.dart';
import '../../../analysis/models/analysis_script.dart';

part 'shareable_template.freezed.dart';
part 'shareable_template.g.dart';

/// Shareable template format for decentralized template sharing.
///
/// This model wraps a TrackerTemplate with optional aesthetics and analysis
/// scripts for sharing via GitHub Gists, repositories, or direct URLs.
/// 
/// All templates are MIT licensed by default.
@freezed
abstract class ShareableTemplate with _$ShareableTemplate {
  const ShareableTemplate._();

  const factory ShareableTemplate({
    /// Schema version for compatibility checking (e.g., "1.0")
    required String version,
    
    /// Creator attribution information
    required AuthorCredit author,
    
    /// Core template structure (REQUIRED)
    required TrackerTemplateModel template,
    
    /// Visual styling (OPTIONAL - users can apply their own)
    TemplateAestheticsModel? aesthetics,
    
    /// Analysis configurations (OPTIONAL - charts, insights, aggregations)
    List<AnalysisScriptModel>? analysisScripts,
    
    /// Optional template description for sharing
    String? description,

    /// Creation timestamp
    DateTime? createdAt,

    /// Category for catalog grouping (e.g., "health", "fitness")
    required String category,

    /// Tags for filtering and search
    List<String>? tags,
  }) = _ShareableTemplate;

  /// Creates from JSON map
  factory ShareableTemplate.fromJson(Map<String, dynamic> json) =>
      _$ShareableTemplateFromJson(json);

  /// Factory constructor for creating a shareable template
  factory ShareableTemplate.create({
    required AuthorCredit author,
    required TrackerTemplateModel template,
    required String category,
    TemplateAestheticsModel? aesthetics,
    List<AnalysisScriptModel>? analysisScripts,
    String? description,
    List<String>? tags,
  }) {
    return ShareableTemplate(
      version: '1.0',
      author: author,
      template: template,
      aesthetics: aesthetics,
      analysisScripts: analysisScripts,
      description: description,
      createdAt: DateTime.now(),
      category: category,
      tags: tags,
    );
  }

  /// Replaces internal UUIDs with clean sequential IDs for export.
  ///
  /// Produces human-readable JSON where field IDs are "field-1", "field-2",
  /// sub-fields are "field-2-sub-1", etc. All internal references (aesthetics
  /// templateId, analysis script fieldIds) are remapped consistently.
  ShareableTemplate sanitizeForExport() {
    const exportTemplateId = 'template';
    final idMap = <String, String>{};

    // Remap fields with sequential IDs
    final sanitizedFields = <TemplateField>[];
    for (int i = 0; i < template.fields.length; i++) {
      final field = template.fields[i];
      final cleanId = 'field-${i + 1}';
      idMap[field.id] = cleanId;

      // Remap sub-fields for group type
      List<TemplateField>? sanitizedSubFields;
      if (field.subFields != null) {
        sanitizedSubFields = [];
        for (int j = 0; j < field.subFields!.length; j++) {
          final sub = field.subFields![j];
          final cleanSubId = '$cleanId-sub-${j + 1}';
          idMap[sub.id] = cleanSubId;
          sanitizedSubFields.add(sub.copyWith(id: cleanSubId));
        }
      }

      sanitizedFields.add(field.copyWith(
        id: cleanId,
        subFields: sanitizedSubFields,
      ));
    }

    final sanitizedTemplate = template.copyWith(
      id: exportTemplateId,
      fields: sanitizedFields,
    );

    // Remap aesthetics
    final sanitizedAesthetics = aesthetics?.copyWith(
      id: 'aesthetics',
      templateId: exportTemplateId,
    );

    // Remap analysis scripts
    final sanitizedScripts = analysisScripts?.map((script) {
      final newFieldId = idMap[script.fieldId] ?? script.fieldId;
      return script.copyWith(
        id: 'script-${analysisScripts!.indexOf(script) + 1}',
        fieldId: newFieldId,
      );
    }).toList();

    return copyWith(
      template: sanitizedTemplate,
      aesthetics: sanitizedAesthetics,
      analysisScripts: sanitizedScripts,
    );
  }
}

/// Author attribution for shared templates.
@freezed
abstract class AuthorCredit with _$AuthorCredit {
  const factory AuthorCredit({
    /// Author name or handle (e.g., "@PrivacyQueen", "John Doe")
    required String name,
    
    /// Optional link to author profile or website
    String? url,
  }) = _AuthorCredit;

  /// Creates from JSON map
  factory AuthorCredit.fromJson(Map<String, dynamic> json) =>
      _$AuthorCreditFromJson(json);

  /// Factory constructor for creating author credit
  factory AuthorCredit.create({
    required String name,
    String? url,
  }) {
    return AuthorCredit(
      name: name,
      url: url,
    );
  }
}