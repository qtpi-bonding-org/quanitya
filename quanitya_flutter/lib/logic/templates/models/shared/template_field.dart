import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../enums/field_enum.dart';
import '../../enums/dimension_enum.dart';
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
class TemplateField with _$TemplateField {
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

    /// Required when type is dimension - defines the physical measurement concept
    DimensionEnum? dimension,

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
    DimensionEnum? dimension,
    String? targetTemplateId,
    List<String>? options,
    List<FieldValidator> validators = const [],
    Object? defaultValue,
  }) {
    return TemplateField(
      id: const Uuid().v4(),
      isDeleted: isDeleted,
      label: label,
      type: type,
      uiElement: uiElement,
      isList: isList,
      dimension: dimension,
      targetTemplateId: targetTemplateId,
      options: options,
      validators: validators,
      defaultValue: defaultValue,
    );
  }
}
