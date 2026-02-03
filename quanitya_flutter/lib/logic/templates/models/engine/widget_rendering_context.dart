import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import '../shared/template_field.dart';
import '../shared/field_validator.dart';

part 'widget_rendering_context.freezed.dart';

/// Context object that bundles all data needed to render a widget from AI atomic field decisions.
///
/// This contains:
/// - The atomic field decision (field type + UI element + validation properties)
/// - Resolved color mappings from AI color assignments
/// - WCAG AA compliance validation results
/// - Current field value and change handlers
@freezed
class WidgetRenderingContext with _$WidgetRenderingContext {
  const factory WidgetRenderingContext({
    /// The template field containing atomic field decision data
    required TemplateField field,

    /// Field validation rules extracted from atomic field decision
    required List<FieldValidator> validators,

    /// Color palette with AI-generated colors (color1, color2, etc.)
    required IColorPalette colorPalette,

    /// AI's color role mappings for this specific UI element
    /// Maps ColorRole (primary, secondary, text) to ColorPaletteColor (color1, color2, neutral1)
    required Map<String, String> colorMappings,

    /// Resolved colors with WCAG AA compliance adjustments applied
    /// Maps ColorRole to actual Flutter Color objects
    required Map<String, Color> resolvedColors,

    /// Current value of the field (for form state management)
    required dynamic currentValue,

    /// Callback when field value changes
    required ValueChanged<dynamic> onValueChanged,

    /// Whether the field is currently enabled for interaction
    @Default(true) bool isEnabled,

    /// Whether to show validation errors
    @Default(false) bool showValidationErrors,

    /// Current validation error message, if any
    String? validationError,
  }) = _WidgetRenderingContext;

  const WidgetRenderingContext._();

  /// Gets the UI element type from the field's atomic decision
  /// Note: This will need to be added to TemplateField model or passed separately
  String get uiElementType =>
      'textField'; // TODO: Get from field or pass separately

  /// Gets a resolved color by role name, with fallback to default colors
  Color getColorByRole(String roleName) {
    return resolvedColors[roleName] ?? Colors.grey;
  }

  /// Checks if the field has a specific validation rule
  bool hasValidator(ValidatorType validatorType) {
    return validators.any((v) => v.validatorType == validatorType);
  }

  /// Gets validation data for a specific validator type
  Map<String, dynamic>? getValidatorData(ValidatorType validatorType) {
    final validator = validators
        .where((v) => v.validatorType == validatorType)
        .firstOrNull;
    return validator?.validatorData;
  }

  /// Gets numeric validation bounds (min/max) if present
  ({double? min, double? max}) getNumericBounds() {
    final numericData = getValidatorData(ValidatorType.numeric);
    if (numericData == null) return (min: null, max: null);

    return (
      min: numericData['min']?.toDouble(),
      max: numericData['max']?.toDouble(),
    );
  }

  /// Gets enumerated options if this is an enumerated field
  List<String> getEnumeratedOptions() {
    // For enumerated fields, options might be stored differently
    // This is a placeholder implementation
    return [];
  }
}
