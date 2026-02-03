import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../logic/templates/models/shared/template_aesthetics.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../widgets/editor/schedule_section.dart';

part 'template_editor_state.freezed.dart';

enum TemplateEditorOperation {
  load,
  updateBasicInfo,
  addField,
  updateField,
  removeField,
  reorderFields,
  updateAesthetics,
  updateSchedule,
  save,
  discard,
}

/// State for the unified template editor
/// Agnostic to how the user entered - just edits templates
@freezed
class TemplateEditorState
    with _$TemplateEditorState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateEditorState._();

  const factory TemplateEditorState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateEditorOperation? lastOperation,

    // Template being edited (null = new template)
    TrackerTemplateModel? template,
    TemplateAestheticsModel? aesthetics,

    // Basic info editing
    @Default('') String templateName,
    @Default('') String templateDescription,

    // Field editing
    @Default([]) List<TemplateField> fields,
    String? editingFieldId,

    // Preview mode
    @Default(false) bool isPreviewMode,
    @Default({}) Map<String, dynamic> previewValues,
    
    // Schedule/Reminder settings
    @Default(ScheduleFrequency.off) ScheduleFrequency scheduleFrequency,
    @Default(null) TimeOfDay? scheduleTime,
    @Default([]) List<String> scheduleWeeklyDays,
  }) = _TemplateEditorState;
}

extension TemplateEditorStateX on TemplateEditorState {
  /// Get the complete template with aesthetics for saving
  TemplateWithAesthetics? get completeTemplate {
    if (aesthetics == null) return null;

    // Create or update the template
    final finalTemplate =
        template?.copyWith(
          name: templateName.isNotEmpty ? templateName : template!.name,
          fields: fields,
          updatedAt: DateTime.now(),
        ) ??
        TrackerTemplateModel.create(
          name: templateName.isNotEmpty ? templateName : 'Untitled Template',
          fields: fields,
        );

    return TemplateWithAesthetics(
      template: finalTemplate,
      aesthetics: aesthetics!.copyWith(
        templateId: finalTemplate.id,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Whether the template has unsaved changes
  bool get hasUnsavedChanges {
    if (template == null) return fields.isNotEmpty || templateName.isNotEmpty;

    return template!.name != templateName ||
        !_fieldsEqual(template!.fields, fields);
  }

  bool _fieldsEqual(List<TemplateField> a, List<TemplateField> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Whether we can save the template
  bool get canSave {
    return templateName.trim().isNotEmpty &&
        fields.isNotEmpty &&
        aesthetics != null;
  }
}
