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
  toggleHidden,
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

    // Preview values (temporary, used by preview sheet)
    @Default({}) Map<String, dynamic> previewValues,
    
    // Schedule/Reminder settings
    @Default(ScheduleFrequency.off) ScheduleFrequency scheduleFrequency,
    @Default(null) int? scheduleHour,
    @Default(null) int? scheduleMinute,
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

  /// Whether we can save the template
  bool get canSave {
    return templateName.trim().isNotEmpty &&
        fields.isNotEmpty &&
        aesthetics != null;
  }
}
