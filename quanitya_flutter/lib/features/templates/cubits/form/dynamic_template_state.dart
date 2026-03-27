import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../logic/templates/models/shared/tracker_template.dart';

part 'dynamic_template_state.freezed.dart';

/// State for dynamic template form - manages the WHOLE template's field values.
///
/// Users fill out all fields in the template, then submit as one LogEntry.
@freezed
abstract class DynamicTemplateState
    with _$DynamicTemplateState, UiFlowStateMixin
    implements IUiFlowState {
  const DynamicTemplateState._();

  const factory DynamicTemplateState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,

    /// The template being filled out
    TrackerTemplateModel? template,

    /// Field values keyed by field.id (covers ALL fields in template)
    @Default({}) Map<String, dynamic> values,

    /// Validation errors keyed by field.id (null = valid)
    @Default({}) Map<String, String?> fieldErrors,

    /// Last operation performed (for message mapping)
    DynamicTemplateOperation? lastOperation,
  }) = _DynamicTemplateState;

  /// Whether the form has any validation errors
  bool get hasValidationErrors => fieldErrors.values.any((e) => e != null);

  /// Whether all required fields have values
  bool get isComplete {
    if (template == null) return false;
    for (final field in template!.fields) {
      final value = values[field.id];
      if (value == null || (value is String && value.isEmpty)) {
        return false;
      }
    }
    return true;
  }

  /// Get value for a specific field
  dynamic getValue(String fieldId) => values[fieldId];

  /// Get error for a specific field
  String? getError(String fieldId) => fieldErrors[fieldId];
}

/// Operations that can be performed on the dynamic template form
enum DynamicTemplateOperation {
  load,
  validate,
  submit,
  clear,
}
