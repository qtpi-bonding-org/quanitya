import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../infrastructure/config/debug_log.dart';
import '../../../analysis/models/analysis_script.dart';
import '../../models/shared/shareable_template.dart';
import '../../models/shared/template_aesthetics.dart';
import '../../models/shared/template_field.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart'
    show TemplateWithAesthetics;

const _tag = 'logic/templates/services/sharing/shareable_template_staging';

/// In-memory staging area for a shareable template being imported.
///
/// Holds a [ShareableTemplate], converts it to local format (new UUIDs),
/// and exposes getters for each part. Consumers pull what they need
/// and handle persistence themselves. This service does NO database writes.
///
/// All import paths (gallery batch, browse sheet, URL import) stage
/// through this service for consistency.
@lazySingleton
class ShareableTemplateStaging {
  ShareableTemplate? _staged;
  TemplateWithAesthetics? _converted;

  /// Stage a shareable template for import.
  ///
  /// Converts to local format (new UUIDs) and holds in memory.
  void stage(ShareableTemplate shareable) {
    _staged = shareable;
    _converted = _convert(shareable);
    Log.d(_tag, 'Staged: ${shareable.template.name} '
        '(${shareable.analysisScripts?.length ?? 0} scripts)');
  }

  /// Whether a template is currently staged.
  bool get hasStaged => _staged != null;

  /// The full original shareable template.
  ShareableTemplate? get staged => _staged;

  /// The converted local template + aesthetics (new UUIDs).
  TemplateWithAesthetics? get templateWithAesthetics => _converted;

  /// Analysis scripts remapped with new UUIDs and templateId.
  ///
  /// [templateId] overrides the staging template ID — use the final saved
  /// template ID since create mode generates a new one on save.
  ///
  /// Returns empty list if no scripts or nothing staged.
  List<AnalysisScriptModel> remappedScripts({String? templateId}) {
    final scripts = _staged?.analysisScripts;
    final originalFields = _staged?.template.fields;
    final newFields = _converted?.template.fields;
    if (scripts == null || scripts.isEmpty ||
        originalFields == null || newFields == null) return [];

    final effectiveTemplateId = templateId ?? _converted?.template.id ?? '';

    // Build old field UUID → new field UUID map
    final fieldIdMap = <String, String>{};
    for (var i = 0; i < originalFields.length && i < newFields.length; i++) {
      fieldIdMap[originalFields[i].id] = newFields[i].id;
      final origSubs = originalFields[i].subFields;
      final newSubs = newFields[i].subFields;
      if (origSubs != null && newSubs != null) {
        for (var j = 0; j < origSubs.length && j < newSubs.length; j++) {
          fieldIdMap[origSubs[j].id] = newSubs[j].id;
        }
      }
    }

    return scripts.map((script) {
      final newFieldId = fieldIdMap[script.fieldId] ?? script.fieldId;
      return script.copyWith(
        id: const Uuid().v4(),
        templateId: effectiveTemplateId,
        fieldId: newFieldId,
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  /// Whether the staged template has analysis scripts.
  bool get hasScripts =>
      _staged?.analysisScripts != null &&
      _staged!.analysisScripts!.isNotEmpty;

  /// Discard the staged template.
  void clear() {
    _staged = null;
    _converted = null;
  }

  /// Convert shareable → local format with new UUIDs.
  TemplateWithAesthetics _convert(ShareableTemplate shareable) {
    final templateId = const Uuid().v4();

    final newFields = shareable.template.fields.map((field) {
      final newSubFields = field.subFields?.map((sf) {
        return sf.copyWith(id: const Uuid().v4());
      }).toList();
      return field.copyWith(
        id: const Uuid().v4(),
        subFields: newSubFields,
      );
    }).toList();

    final localTemplate = shareable.template.copyWith(
      id: templateId,
      fields: newFields,
      updatedAt: DateTime.now(),
      isArchived: false,
      isHidden: false,
    );

    TemplateAestheticsModel? localAesthetics;
    if (shareable.aesthetics != null) {
      localAesthetics = shareable.aesthetics!.copyWith(
        id: const Uuid().v4(),
        templateId: templateId,
        updatedAt: DateTime.now(),
      );
    }

    return TemplateWithAesthetics(
      template: localTemplate,
      aesthetics:
          localAesthetics ??
          TemplateAestheticsModel.defaults(templateId: templateId),
    );
  }

}
