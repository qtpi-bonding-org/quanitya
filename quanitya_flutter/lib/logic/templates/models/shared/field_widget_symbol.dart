import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/field_enum.dart';
import '../../enums/ui_element_enum.dart';
import 'field_validator.dart';

part 'field_widget_symbol.freezed.dart';
part 'field_widget_symbol.g.dart';

/// Symbolic representation of valid field-widget-validator combinations.
///
/// This model represents a valid triplet of field type, UI element, and
/// required validators without creating concrete instances. It serves as
/// a blueprint for generating actual TemplateField and FieldValidator
/// instances while ensuring type safety through UI-validator coupling rules.
@freezed
class FieldWidgetSymbol with _$FieldWidgetSymbol {
  const factory FieldWidgetSymbol({
    /// The data field type (integer, float, text, boolean, etc.)
    required FieldEnum fieldType,

    /// The UI widget type for displaying this field (slider, textField, etc.)
    required UiElementEnum uiElement,

    /// List of validator types required for this UI element
    required List<ValidatorType> requiredValidators,
  }) = _FieldWidgetSymbol;

  /// Creates a FieldWidgetSymbol from JSON map
  factory FieldWidgetSymbol.fromJson(Map<String, dynamic> json) =>
      _$FieldWidgetSymbolFromJson(json);

  /// Factory constructor for numeric field with slider UI
  ///
  /// Creates a symbol for numeric input using a slider widget.
  /// Automatically includes numeric validator as required.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.numericSlider();
  /// // fieldType: FieldEnum.integer, uiElement: UiElementEnum.slider,
  /// // requiredValidators: [ValidatorType.numeric]
  /// ```
  factory FieldWidgetSymbol.numericSlider({
    FieldEnum fieldType = FieldEnum.integer,
  }) {
    assert(
      fieldType == FieldEnum.integer || fieldType == FieldEnum.float,
      'Numeric slider only supports integer or float field types',
    );

    return FieldWidgetSymbol(
      fieldType: fieldType,
      uiElement: UiElementEnum.slider,
      requiredValidators: const [ValidatorType.numeric],
    );
  }

  /// Factory constructor for numeric field with stepper UI
  ///
  /// Creates a symbol for numeric input using a stepper widget.
  /// Automatically includes numeric validator as required.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.numericStepper(fieldType: FieldEnum.float);
  /// // fieldType: FieldEnum.float, uiElement: UiElementEnum.stepper,
  /// // requiredValidators: [ValidatorType.numeric]
  /// ```
  factory FieldWidgetSymbol.numericStepper({
    FieldEnum fieldType = FieldEnum.integer,
  }) {
    assert(
      fieldType == FieldEnum.integer || fieldType == FieldEnum.float,
      'Numeric stepper only supports integer or float field types',
    );

    return FieldWidgetSymbol(
      fieldType: fieldType,
      uiElement: UiElementEnum.stepper,
      requiredValidators: const [ValidatorType.numeric],
    );
  }

  /// Factory constructor for enumerated field with dropdown UI
  ///
  /// Creates a symbol for selection input using a dropdown widget.
  /// Automatically includes enumerated validator as required.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.enumeratedDropdown();
  /// // fieldType: FieldEnum.enumerated, uiElement: UiElementEnum.dropdown,
  /// // requiredValidators: [ValidatorType.enumerated]
  /// ```
  factory FieldWidgetSymbol.enumeratedDropdown() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.enumerated,
      uiElement: UiElementEnum.dropdown,
      requiredValidators: [ValidatorType.enumerated],
    );
  }

  /// Factory constructor for enumerated field with radio UI
  ///
  /// Creates a symbol for selection input using radio buttons.
  /// Automatically includes enumerated validator as required.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.enumeratedRadio();
  /// // fieldType: FieldEnum.enumerated, uiElement: UiElementEnum.radio,
  /// // requiredValidators: [ValidatorType.enumerated]
  /// ```
  factory FieldWidgetSymbol.enumeratedRadio() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.enumerated,
      uiElement: UiElementEnum.radio,
      requiredValidators: [ValidatorType.enumerated],
    );
  }

  /// Factory constructor for enumerated field with chips UI
  ///
  /// Creates a symbol for selection input using chips.
  /// Automatically includes enumerated validator as required.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.enumeratedChips();
  /// // fieldType: FieldEnum.enumerated, uiElement: UiElementEnum.chips,
  /// // requiredValidators: [ValidatorType.enumerated]
  /// ```
  factory FieldWidgetSymbol.enumeratedChips() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.enumerated,
      uiElement: UiElementEnum.chips,
      requiredValidators: [ValidatorType.enumerated],
    );
  }

  /// Factory constructor for text field with optional text validation
  ///
  /// Creates a symbol for text input using a text field widget.
  /// Text validators are optional for text fields.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.textField();
  /// // fieldType: FieldEnum.text, uiElement: UiElementEnum.textField,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.textField() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.text,
      uiElement: UiElementEnum.textField,
      requiredValidators: [], // Text validators are optional
    );
  }

  /// Factory constructor for text area with optional text validation
  ///
  /// Creates a symbol for multi-line text input using a text area widget.
  /// Text validators are optional for text areas.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.textArea();
  /// // fieldType: FieldEnum.text, uiElement: UiElementEnum.textArea,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.textArea() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.text,
      uiElement: UiElementEnum.textArea,
      requiredValidators: [], // Text validators are optional
    );
  }

  /// Factory constructor for boolean field with toggle switch UI
  ///
  /// Creates a symbol for boolean input using a toggle switch widget.
  /// No validators are required for boolean fields.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.booleanToggle();
  /// // fieldType: FieldEnum.boolean, uiElement: UiElementEnum.toggleSwitch,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.booleanToggle() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.boolean,
      uiElement: UiElementEnum.toggleSwitch,
      requiredValidators: [], // Boolean fields don't need validators
    );
  }

  /// Factory constructor for boolean field with checkbox UI
  ///
  /// Creates a symbol for boolean input using a checkbox widget.
  /// No validators are required for boolean fields.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.booleanCheckbox();
  /// // fieldType: FieldEnum.boolean, uiElement: UiElementEnum.checkbox,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.booleanCheckbox() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.boolean,
      uiElement: UiElementEnum.checkbox,
      requiredValidators: [], // Boolean fields don't need validators
    );
  }

  /// Factory constructor for datetime field with date picker UI
  ///
  /// Creates a symbol for date input using a date picker widget.
  /// No validators are required for date picker fields.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.datePicker();
  /// // fieldType: FieldEnum.datetime, uiElement: UiElementEnum.datePicker,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.datePicker() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.datetime,
      uiElement: UiElementEnum.datePicker,
      requiredValidators: [], // Date pickers don't need validators
    );
  }

  /// Factory constructor for datetime field with time picker UI
  ///
  /// Creates a symbol for time input using a time picker widget.
  /// No validators are required for time picker fields.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.timePicker();
  /// // fieldType: FieldEnum.datetime, uiElement: UiElementEnum.timePicker,
  /// // requiredValidators: []
  /// ```
  factory FieldWidgetSymbol.timePicker() {
    return const FieldWidgetSymbol(
      fieldType: FieldEnum.datetime,
      uiElement: UiElementEnum.timePicker,
      requiredValidators: [], // Time pickers don't need validators
    );
  }

  /// Factory constructor for dimension field with appropriate UI
  ///
  /// Creates a symbol for dimension input. Dimensions typically use
  /// numeric input widgets with dimension-specific validation.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.dimensionField();
  /// // fieldType: FieldEnum.dimension, uiElement: UiElementEnum.textField,
  /// // requiredValidators: [ValidatorType.dimension]
  /// ```
  factory FieldWidgetSymbol.dimensionField({
    UiElementEnum uiElement = UiElementEnum.textField,
  }) {
    assert(
      uiElement == UiElementEnum.textField ||
          uiElement == UiElementEnum.slider ||
          uiElement == UiElementEnum.stepper,
      'Dimension fields support textField, slider, or stepper UI elements',
    );

    // Slider and stepper require numeric validator + dimension validator
    // TextField only needs dimension validator
    final validators =
        (uiElement == UiElementEnum.slider ||
            uiElement == UiElementEnum.stepper)
        ? [ValidatorType.numeric, ValidatorType.dimension]
        : [ValidatorType.dimension];

    return FieldWidgetSymbol(
      fieldType: FieldEnum.dimension,
      uiElement: uiElement,
      requiredValidators: validators,
    );
  }

  /// Factory constructor for reference field with appropriate UI
  ///
  /// Creates a symbol for reference input. References typically use
  /// dropdown or text field widgets with reference-specific validation.
  ///
  /// Example:
  /// ```dart
  /// final symbol = FieldWidgetSymbol.referenceField();
  /// // fieldType: FieldEnum.reference, uiElement: UiElementEnum.dropdown,
  /// // requiredValidators: [ValidatorType.enumerated, ValidatorType.reference]
  /// ```
  factory FieldWidgetSymbol.referenceField({
    UiElementEnum uiElement = UiElementEnum.dropdown,
  }) {
    assert(
      uiElement == UiElementEnum.dropdown ||
          uiElement == UiElementEnum.textField,
      'Reference fields support dropdown or textField UI elements',
    );

    // Dropdown requires enumerated validator + reference validator
    // TextField only needs reference validator
    final validators = uiElement == UiElementEnum.dropdown
        ? [ValidatorType.enumerated, ValidatorType.reference]
        : [ValidatorType.reference];

    return FieldWidgetSymbol(
      fieldType: FieldEnum.reference,
      uiElement: uiElement,
      requiredValidators: validators,
    );
  }
}
