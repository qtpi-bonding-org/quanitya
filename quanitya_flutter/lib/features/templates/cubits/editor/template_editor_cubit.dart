import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/template_aesthetics.dart';
import '../../../../logic/templates/enums/ai/template_preset.dart';
import '../../../../logic/schedules/models/schedule.dart';
import '../../../../logic/schedules/services/schedule_service.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../data/repositories/schedule_repository.dart';
import '../../../../data/interfaces/analysis_script_interface.dart';
import '../../../../infrastructure/permissions/permission_service.dart';
import '../../../../logic/templates/services/sharing/shareable_template_staging.dart';
import '../../../../logic/templates/enums/field_enum.dart';
import '../../widgets/editor/schedule_section.dart';
import 'template_editor_state.dart';

/// Unified cubit for template creation and editing.
///
/// Simple and agnostic:
/// - loadTemplate(templateWithAesthetics) - Edit existing template
/// - createNew() - Create new template from scratch
@injectable
class TemplateEditorCubit extends QuanityaCubit<TemplateEditorState> {
  final TemplateWithAestheticsRepository _repository;
  final ScheduleRepository _scheduleRepository;
  final PermissionService _permissionService;
  final ScheduleService _scheduleService;
  final ShareableTemplateStaging _staging;
  final IAnalysisScriptRepository _scriptRepository;

  TemplateEditorCubit(this._repository, this._scheduleRepository, this._permissionService, this._scheduleService, this._staging, this._scriptRepository) : super(const TemplateEditorState());

  // ─────────────────────────────────────────────────────────────────────────
  // Entry Points
  // ─────────────────────────────────────────────────────────────────────────

  /// Populate the editor with template data without marking it as an existing template.
  /// Used for AI generation, gallery import, and URL import — stays in "create" mode.
  void populateFromTemplate(TemplateWithAesthetics templateWithAesthetics) {
    emit(
      state.copyWith(
        template: null,
        aesthetics: templateWithAesthetics.aesthetics,
        templateName: templateWithAesthetics.template.name,
        templateDescription: '',
        fields: List.from(templateWithAesthetics.template.fields),
        lastOperation: TemplateEditorOperation.load,
        status: UiFlowStatus.idle,
      ),
    );
  }

  /// Load an existing template for editing (from saved templates)
  Future<void> loadTemplate(TemplateWithAesthetics templateWithAesthetics) async {
    emit(
      state.copyWith(
        template: templateWithAesthetics.template,
        aesthetics: templateWithAesthetics.aesthetics,
        templateName: templateWithAesthetics.template.name,
        templateDescription:
            '', // TrackerTemplateModel doesn't have description
        fields: List.from(templateWithAesthetics.template.fields),
        lastOperation: TemplateEditorOperation.load,
        status: UiFlowStatus.idle,
      ),
    );

    // Load existing schedule for this template
    await _loadExistingSchedule(templateWithAesthetics.template.id);
  }

  /// Load existing schedule from the database and populate editor state.
  Future<void> _loadExistingSchedule(String templateId) async {
    final schedules = await _scheduleRepository.getActiveSchedulesForTemplate(templateId);
    if (schedules.isEmpty) return;

    final schedule = schedules.first;
    final rule = schedule.recurrenceRule;

    // Parse frequency from RRULE
    ScheduleFrequency frequency = ScheduleFrequency.off;
    int? hour;
    int? minute;
    List<String> weeklyDays = [];

    if (rule.contains('FREQ=DAILY')) {
      frequency = ScheduleFrequency.daily;
    } else if (rule.contains('FREQ=WEEKLY')) {
      frequency = ScheduleFrequency.weekly;
      // Parse BYDAY
      final byDayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
      if (byDayMatch != null) {
        weeklyDays = byDayMatch.group(1)!.split(',');
      }
    }

    // Parse time from BYHOUR and BYMINUTE
    final hourMatch = RegExp(r'BYHOUR=(\d+)').firstMatch(rule);
    final minuteMatch = RegExp(r'BYMINUTE=(\d+)').firstMatch(rule);
    if (hourMatch != null) {
      hour = int.parse(hourMatch.group(1)!);
      minute = minuteMatch != null ? int.parse(minuteMatch.group(1)!) : 0;
    }

    emit(state.copyWith(
      scheduleFrequency: frequency,
      scheduleHour: hour,
      scheduleMinute: minute,
      scheduleWeeklyDays: weeklyDays,
    ));
  }

  /// Create a new template from scratch
  void createNew() {
    // Create default aesthetics
    final defaultAesthetics = TemplateAestheticsModel.defaults(templateId: '');

    emit(
      state.copyWith(
        template: null,
        aesthetics: defaultAesthetics,
        templateName: '',
        templateDescription: '',
        fields: [],
        lastOperation: TemplateEditorOperation.load,
        status: UiFlowStatus.idle,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Basic Info Editing
  // ─────────────────────────────────────────────────────────────────────────

  void updateTemplateName(String name) {
    emit(
      state.copyWith(
        templateName: name,
        lastOperation: TemplateEditorOperation.updateBasicInfo,
      ),
    );
  }

  void updateTemplateDescription(String description) {
    emit(
      state.copyWith(
        templateDescription: description,
        lastOperation: TemplateEditorOperation.updateBasicInfo,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Field Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Add a pre-built field to the template
  void addFieldFromTemplate(TemplateField field) {
    final updatedFields = [...state.fields, field];

    emit(
      state.copyWith(
        fields: updatedFields,
        lastOperation: TemplateEditorOperation.addField,
      ),
    );
  }

  /// Update an existing field
  void updateField(String fieldId, TemplateField updatedField) {
    final updatedFields = state.fields.map((field) {
      return field.id == fieldId ? updatedField : field;
    }).toList();

    emit(
      state.copyWith(
        fields: updatedFields,
        lastOperation: TemplateEditorOperation.updateField,
      ),
    );
  }

  /// Remove a field from the template
  void removeField(String fieldId) {
    final updatedFields = state.fields
        .where((field) => field.id != fieldId)
        .toList();

    emit(
      state.copyWith(
        fields: updatedFields,
        lastOperation: TemplateEditorOperation.removeField,
      ),
    );
  }

  /// Reorder fields (for drag & drop)
  void reorderFields(int oldIndex, int newIndex) {
    final updatedFields = List<TemplateField>.from(state.fields);

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final field = updatedFields.removeAt(oldIndex);
    updatedFields.insert(newIndex, field);

    emit(
      state.copyWith(
        fields: updatedFields,
        lastOperation: TemplateEditorOperation.reorderFields,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Field Grouping
  // ─────────────────────────────────────────────────────────────────────────

  /// Group selected fields into a new group field.
  /// Removes them from top-level and creates a group at the first selected field's position.
  void groupFields(List<String> fieldIds, String groupLabel) {
    if (fieldIds.length < 2) return;

    final updatedFields = List<TemplateField>.from(state.fields);
    final subFields = <TemplateField>[];
    int insertIndex = updatedFields.length;

    // Collect sub-fields and find the earliest index
    for (final id in fieldIds) {
      final index = updatedFields.indexWhere((f) => f.id == id);
      if (index != -1) {
        if (index < insertIndex) insertIndex = index;
        subFields.add(updatedFields[index]);
      }
    }

    // Remove selected fields (reverse order to preserve indices)
    updatedFields.removeWhere((f) => fieldIds.contains(f.id));

    // Create group and insert at earliest position
    final group = TemplateField.create(
      type: FieldEnum.group,
      label: groupLabel,
      subFields: subFields,
    );
    if (insertIndex > updatedFields.length) insertIndex = updatedFields.length;
    updatedFields.insert(insertIndex, group);

    emit(state.copyWith(
      fields: updatedFields,
      lastOperation: TemplateEditorOperation.updateField,
    ));
  }

  /// Dissolve a group — promotes all sub-fields back to top-level at the group's position.
  void ungroupField(String groupFieldId) {
    final updatedFields = List<TemplateField>.from(state.fields);
    final groupIndex = updatedFields.indexWhere((f) => f.id == groupFieldId);
    if (groupIndex == -1) return;

    final group = updatedFields[groupIndex];
    if (group.type != FieldEnum.group || group.subFields == null) return;

    updatedFields.removeAt(groupIndex);
    updatedFields.insertAll(groupIndex, group.subFields!);

    emit(state.copyWith(
      fields: updatedFields,
      lastOperation: TemplateEditorOperation.updateField,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Aesthetics Management
  // ─────────────────────────────────────────────────────────────────────────

  void updateAesthetics(TemplateAestheticsModel aesthetics) {
    emit(state.copyWith(
      aesthetics: aesthetics,
      lastOperation: TemplateEditorOperation.updateAesthetics,
    ));
  }

  /// Update an accent color in the palette (interactive elements)
  void updateAccentColor(int index, String hexColor) {
    if (state.aesthetics == null) return;

    final accents = List<String>.from(state.aesthetics!.palette.accents);
    if (index >= 0 && index < accents.length) {
      accents[index] = hexColor;
      final updatedPalette = state.aesthetics!.palette.copyWith(accents: accents);
      final updatedAesthetics =
          state.aesthetics!.copyWith(palette: updatedPalette);
      emit(state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ));
    }
  }

  /// Update a tone color in the palette (text variations)
  void updateToneColor(int index, String hexColor) {
    if (state.aesthetics == null) return;

    final tones = List<String>.from(state.aesthetics!.palette.tones);
    if (index >= 0 && index < tones.length) {
      tones[index] = hexColor;
      final updatedPalette = state.aesthetics!.palette.copyWith(tones: tones);
      final updatedAesthetics =
          state.aesthetics!.copyWith(palette: updatedPalette);
      emit(state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ));
    }
  }

  /// Update the template icon (format: "packname:iconname")
  void updateTemplateIcon(String icon) {
    if (state.aesthetics == null) return;

    final updatedAesthetics = state.aesthetics!.copyWith(
      icon: icon,
      emoji: null, // Clear emoji if setting icon
    );

    emit(
      state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ),
    );
  }

  /// Update the title font family
  void updateTitleFont(String fontFamily) {
    if (state.aesthetics == null) return;

    final updatedFontConfig = state.aesthetics!.fontConfig.copyWith(
      titleFontFamily: fontFamily,
    );
    final updatedAesthetics = state.aesthetics!.copyWith(
      fontConfig: updatedFontConfig,
    );

    emit(
      state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ),
    );
  }

  /// Update the body font family
  void updateBodyFont(String fontFamily) {
    if (state.aesthetics == null) return;

    final updatedFontConfig = state.aesthetics!.fontConfig.copyWith(
      bodyFontFamily: fontFamily,
    );
    final updatedAesthetics = state.aesthetics!.copyWith(
      fontConfig: updatedFontConfig,
    );

    emit(
      state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ),
    );
  }

  /// Update the container style
  void updateContainerStyle(TemplateContainerStyle containerStyle) {
    if (state.aesthetics == null) return;

    final updatedAesthetics = state.aesthetics!.copyWith(
      containerStyle: containerStyle,
    );

    emit(
      state.copyWith(
        aesthetics: updatedAesthetics,
        lastOperation: TemplateEditorOperation.updateAesthetics,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schedule Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Update the schedule frequency
  void updateScheduleFrequency(ScheduleFrequency frequency) {
    emit(state.copyWith(
      scheduleFrequency: frequency,
      // Set default time if enabling schedule
      scheduleHour: frequency != ScheduleFrequency.off && state.scheduleHour == null
          ? 9
          : state.scheduleHour,
      scheduleMinute: frequency != ScheduleFrequency.off && state.scheduleMinute == null
          ? 0
          : state.scheduleMinute,
      lastOperation: TemplateEditorOperation.updateSchedule,
    ));
  }

  /// Update the schedule time
  void updateScheduleTime(int hour, int minute) {
    emit(state.copyWith(
      scheduleHour: hour,
      scheduleMinute: minute,
      lastOperation: TemplateEditorOperation.updateSchedule,
    ));
  }

  /// Update the weekly days for weekly schedules
  void updateScheduleWeeklyDays(List<String> days) {
    emit(state.copyWith(
      scheduleWeeklyDays: days,
      lastOperation: TemplateEditorOperation.updateSchedule,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Preview
  // ─────────────────────────────────────────────────────────────────────────

  /// Update a preview value (for testing the form)
  /// 
  /// ✅ UI-ONLY STATE: Preview values are temporary form test data that don't persist
  /// to the database. They're only used for testing the form layout and validation
  /// in preview mode. When the user exits preview mode or saves the template, these
  /// values are discarded. Actual log entries are submitted via DynamicTemplateCubit.
  void updatePreviewValue(String fieldId, dynamic value) {
    final updatedValues = Map<String, dynamic>.from(state.previewValues);
    updatedValues[fieldId] = value;

    emit(state.copyWith(previewValues: updatedValues));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save & Discard
  // ─────────────────────────────────────────────────────────────────────────

  /// Save the template to the repository.
  ///
  /// If a shareable template was staged (from gallery/URL import),
  /// persists its analysis scripts with remapped field IDs after
  /// saving the template.
  Future<void> save() async {
    await tryOperation(() async {
      final completeTemplate = state.completeTemplate;
      if (completeTemplate == null) {
        throw StateError('Cannot save incomplete template');
      }

      await _repository.save(completeTemplate);

      // Persist staged analysis scripts — only for fields that survived editing
      if (_staging.hasStaged && _staging.hasScripts) {
        final templateId = completeTemplate.template.id;
        final savedFieldIds = completeTemplate.template.fields
            .map((f) => f.id)
            .toSet();
        for (final script in _staging.remappedScripts(templateId: templateId)) {
          if (savedFieldIds.contains(script.fieldId)) {
            await _scriptRepository.saveScript(script);
          }
        }
      }
      _staging.clear();

      // Save or delete schedule (request notification permission if creating one)
      if (state.scheduleFrequency != ScheduleFrequency.off) {
        await _permissionService.ensureNotification();
      }
      await _saveOrDeleteSchedule(completeTemplate.template.id);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateEditorOperation.save,
      );
    }, emitLoading: true);
  }

  /// Save or delete the schedule for the template.
  ///
  /// If frequency is off, deletes any existing schedule.
  /// Otherwise, updates the existing schedule or creates a new one.
  Future<void> _saveOrDeleteSchedule(String templateId) async {
    final existing = await _scheduleRepository.getSchedulesForTemplate(templateId);

    // If schedule is off, delete schedules (facade handles cleanup)
    if (state.scheduleFrequency == ScheduleFrequency.off) {
      for (final schedule in existing) {
        await _scheduleService.delete(schedule.id);
      }
      return;
    }

    final hour = state.scheduleHour ?? 9;
    final minute = state.scheduleMinute ?? 0;

    final String recurrenceRule;
    switch (state.scheduleFrequency) {
      case ScheduleFrequency.daily:
        recurrenceRule = 'FREQ=DAILY;BYHOUR=$hour;BYMINUTE=$minute';
      case ScheduleFrequency.weekly:
        final days = state.scheduleWeeklyDays.isNotEmpty
            ? state.scheduleWeeklyDays.join(',')
            : 'MO,TU,WE,TH,FR';
        recurrenceRule = 'FREQ=WEEKLY;BYDAY=$days;BYHOUR=$hour;BYMINUTE=$minute';
      case ScheduleFrequency.custom:
      case ScheduleFrequency.off:
        return;
    }

    if (existing.isNotEmpty) {
      // Update existing schedule (facade handles save + generation)
      final updated = existing.first
          .updateRule(recurrenceRule)
          .updateReminder(0);
      await _scheduleService.save(updated);

      // Delete any extra duplicates from the append bug
      for (var i = 1; i < existing.length; i++) {
        await _scheduleService.delete(existing[i].id);
      }
    } else {
      // Create new schedule (facade handles save + generation)
      final schedule = ScheduleModel.create(
        templateId: templateId,
        recurrenceRule: recurrenceRule,
        reminderOffsetMinutes: 0,
      );
      await _scheduleService.save(schedule);
      analytics?.trackScheduleCreated();
    }
  }

  /// Discard changes and reset
  void discard() {
    emit(
      const TemplateEditorState().copyWith(
        lastOperation: TemplateEditorOperation.discard,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Visibility Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle the hidden state of the template.
  /// Hidden templates require biometric auth to view.
  Future<void> toggleHidden() async {
    final templateId = state.template?.id;
    if (templateId == null) return;

    await tryOperation(() async {
      if (state.template!.isHidden) {
        await _repository.unhide(templateId);
      } else {
        await _repository.hide(templateId);
      }

      final updated = await _repository.findById(templateId);
      if (updated != null) {
        return state.copyWith(
          template: updated.template,
          status: UiFlowStatus.success,
          lastOperation: TemplateEditorOperation.toggleHidden,
        );
      }
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: TemplateEditorOperation.toggleHidden,
      );
    }, emitLoading: false);
  }

}
