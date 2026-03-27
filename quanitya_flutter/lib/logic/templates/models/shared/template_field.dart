import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../enums/field_enum.dart';
import '../../enums/measurement_unit.dart';
import '../../enums/ui_element_enum.dart';
import 'field_validator.dart';

part 'template_field.freezed.dart';
part 'template_field.g.dart';

/// Represents a single field definition within a TrackerTemplate.
///
/// This model defines the pure data structure and validation rules
/// for individual form fields in tracker templates. UI presentation
/// is handled separately via TemplateTheme.
@freezed
abstract class TemplateField with _$TemplateField {
  const TemplateField._();
  const factory TemplateField({
    /// Unique identifier for this field (UUID format)
    required String id,

    /// Meta migration flag - when true, field is preserved but hidden from active use
    @Default(false) bool isDeleted,

    /// Display label for the field (e.g., "Weight", "Reps")
    required String label,

    /// Input type that determines data validation and storage
    required FieldEnum type,

    /// UI widget type for rendering this field input.
    /// Valid combinations are enforced by SymbolicCombinationGenerator.
    /// If null, system picks default based on field type.
    UiElementEnum? uiElement,

    /// Whether this field accepts multiple values (stored as JSON array)
    @Default(false) bool isList,

    /// Required when type is dimension - defines the measurement unit
    MeasurementUnit? unit,

    /// Required when type is reference - points to another TrackerTemplate ID
    String? targetTemplateId,

    /// Required when type is enumerated - defines the selectable options
    List<String>? options,

    /// Nested validation rules for this field
    @Default([]) List<FieldValidator> validators,
    
    /// Default value for quicklog - pre-fills the field when logging
    /// Type depends on field type: String, int, double, bool, DateTime (ISO string), etc.
    /// Null means no default (user must enter value or field is empty)
    Object? defaultValue,

    /// Sub-fields for group type. Required when type == group.
    /// Each sub-field is a full TemplateField with its own validators and defaults.
    /// Sub-fields must not have type == group (one level of nesting).
    List<TemplateField>? subFields,
  }) = _TemplateField;

  /// Creates a TemplateField from JSON map
  factory TemplateField.fromJson(Map<String, dynamic> json) =>
      _$TemplateFieldFromJson(json);

  /// Factory constructor that generates a new TemplateField with UUID
  factory TemplateField.create({
    required String label,
    required FieldEnum type,
    UiElementEnum? uiElement,
    bool isDeleted = false,
    bool isList = false,
    MeasurementUnit? unit,
    String? targetTemplateId,
    List<String>? options,
    List<FieldValidator> validators = const [],
    Object? defaultValue,
    List<TemplateField>? subFields,
  }) {
    return TemplateField(
      id: const Uuid().v4(),
      isDeleted: isDeleted,
      label: label,
      type: type,
      uiElement: uiElement,
      isList: isList,
      unit: unit,
      targetTemplateId: targetTemplateId,
      options: options,
      validators: validators,
      defaultValue: defaultValue,
      subFields: subFields,
    );
  }
}
