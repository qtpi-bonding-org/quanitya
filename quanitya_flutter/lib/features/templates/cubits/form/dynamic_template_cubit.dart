import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/log_entries/services/log_entry_service.dart';
import '../../../../logic/templates/models/shared/template_field.dart';
import '../../../../logic/templates/models/shared/tracker_template.dart';
import '../../../../logic/templates/services/shared/default_value_handler.dart';
import '../../../../logic/templates/services/shared/field_validators.dart';
import 'dynamic_template_state.dart';

/// Cubit for managing a dynamic template form and log entry submission.
///
/// Manages the WHOLE template - all fields are tracked in state.values
/// and submitted together as a single LogEntry.
@injectable
class DynamicTemplateCubit extends QuanityaCubit<DynamicTemplateState> {
  final LogEntryService _logEntryService;
  final DefaultValueHandler _defaultHandler;

  DynamicTemplateCubit(this._logEntryService, this._defaultHandler)
    : super(const DynamicTemplateState());

  /// Load a template into the form (initializes all field values)
  void loadTemplate(TrackerTemplateModel template) {
    final initialValues = <String, dynamic>{};

    // Initialize ALL fields with default values
    for (final field in template.fields) {
      initialValues[field.id] = _getDefaultValue(field);
    }

    emit(
      state.copyWith(
        template: template,
        values: initialValues,
        fieldErrors: {},
        status: UiFlowStatus.idle,
        lastOperation: DynamicTemplateOperation.load,
      ),
    );
  }

  /// Update a single field value
  /// 
  /// ✅ CORRECT PATTERN: Direct memory update is appropriate here because:
  /// - This is form state that's only submitted when user calls submit()
  /// - Values are NOT persisted until submit() is called
  /// - The repository.save() happens in submit(), not here
  /// - This follows the form-then-submit pattern (not real-time persistence)
  void updateField(String fieldId, dynamic value) {
    final newValues = Map<String, dynamic>.from(state.values);
    newValues[fieldId] = value;

    // Clear error for this field when updated
    final newErrors = Map<String, String?>.from(state.fieldErrors);
    newErrors.remove(fieldId);

    emit(
      state.copyWith(
        values: newValues,
        fieldErrors: newErrors,
      ),
    );
  }

  /// Validate all fields in the template
  bool validate() {
    if (state.template == null) return false;

    final errors = <String, String?>{};

    for (final field in state.template!.fields) {
      final value = state.values[field.id];
      final error = _validateField(field, value);
      if (error != null) {
        errors[field.id] = error;
      }
    }

    emit(
      state.copyWith(
        fieldErrors: errors,
        lastOperation: DynamicTemplateOperation.validate,
      ),
    );

    return errors.isEmpty;
  }

  /// Submit the entire form as a log entry
  Future<void> submit({DateTime? scheduledFor}) async {
    await tryOperation(() async {
      if (state.template == null) {
        throw StateError('No template loaded');
      }

      // Validate all fields first
      if (!validate()) {
        return state.copyWith(
          status: UiFlowStatus.failure,
          lastOperation: DynamicTemplateOperation.submit,
          error: 'Please fix validation errors',
        );
      }

      // Create log entry with ALL field values
      final logEntry = LogEntryModel.logNow(
        templateId: state.template!.id,
        data: state.values,
      );

      // Save via service (triggers webhooks)
      await _logEntryService.saveLogEntry(logEntry);
      analytics?.trackEntryLogged();

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: DynamicTemplateOperation.submit,
      );
    }, emitLoading: true);
  }

  /// Clear the form (reset all fields to defaults)
  void clear() {
    if (state.template != null) {
      loadTemplate(state.template!);
    }
    emit(
      state.copyWith(
        lastOperation: DynamicTemplateOperation.clear,
      ),
    );
  }

  /// Get default value for a field using DefaultValueHandler.
  dynamic _getDefaultValue(TemplateField field) {
    return _defaultHandler.resolveDefault(field);
  }

  /// Validate a single field using centralized FieldValidators.
  String? _validateField(TemplateField field, dynamic value) {
    final validator = FieldValidators.forField(
      label: field.label,
      validators: field.validators,
      isRequired: true, // All fields required by default
    );
    return validator(value);
  }
}
