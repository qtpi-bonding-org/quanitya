import '../field_enum.dart';
import '../ui_element_enum.dart';

/// Maps FieldEnum types to valid UiElementEnum combinations for schema generation.
///
/// This class serves as the single source of truth for valid field-widget
/// combinations, used by the JSON schema generator to constrain AI output.
class FieldWidgetCombinations {
  /// Map of field types to their valid UI element combinations
  static const Map<FieldEnum, List<UiElementEnum>> combinations = {
    // Integer fields can use sliders, text fields, steppers, or timer
    FieldEnum.integer: [
      UiElementEnum.slider,
      UiElementEnum.textField,
      UiElementEnum.stepper,
      UiElementEnum.timer,
    ],

    // Float fields can use sliders, text fields, steppers, or timer
    FieldEnum.float: [
      UiElementEnum.slider,
      UiElementEnum.textField,
      UiElementEnum.stepper,
      UiElementEnum.timer,
    ],

    // Text fields can use single-line or multi-line text inputs
    FieldEnum.text: [
      UiElementEnum.textField,
      UiElementEnum.textArea,
    ],

    // Boolean fields can use switches or checkboxes
    FieldEnum.boolean: [
      UiElementEnum.toggleSwitch,
      UiElementEnum.checkbox,
    ],

    // Enumerated fields can use chips, dropdowns, or radio buttons
    FieldEnum.enumerated: [
      UiElementEnum.chips,
      UiElementEnum.dropdown,
      UiElementEnum.radio,
    ],

    // DateTime fields can use various date/time pickers
    FieldEnum.datetime: [
      UiElementEnum.datePicker,
      UiElementEnum.timePicker,
      UiElementEnum.datetimePicker,
    ],

    // Dimension fields can use sliders or text fields with unit support
    FieldEnum.dimension: [
      UiElementEnum.slider,
      UiElementEnum.textField,
    ],

    // Reference fields are not yet implemented — excluded from AI generation

    // Location fields use the location picker
    FieldEnum.location: [
      UiElementEnum.locationPicker,
    ],

    // Multi-select fields can use chips, dropdowns, or radio buttons
    FieldEnum.multiEnum: [
      UiElementEnum.chips,
      UiElementEnum.dropdown,
      UiElementEnum.radio,
    ],
  };

  /// Gets valid UI elements for a specific field type
  static List<UiElementEnum> getValidUiElements(FieldEnum fieldType) {
    return combinations[fieldType] ?? [];
  }

  /// Validates if a field type and UI element combination is valid
  static bool isValidCombination(FieldEnum fieldType, UiElementEnum uiElement) {
    return combinations[fieldType]?.contains(uiElement) ?? false;
  }

  /// Gets all valid field-UI element pairs as a flat list
  static List<MapEntry<FieldEnum, UiElementEnum>> getAllValidPairs() {
    final pairs = <MapEntry<FieldEnum, UiElementEnum>>[];

    for (final entry in combinations.entries) {
      for (final uiElement in entry.value) {
        pairs.add(MapEntry(entry.key, uiElement));
      }
    }

    return pairs;
  }
}
