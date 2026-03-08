import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_validator_coupling.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';

/// Service that generates all valid symbolic combinations of field types,
/// UI elements, and validators based on coupling rules.
///
/// This generator creates enum tuples for every valid combination while
/// respecting UI-validator coupling constraints and ensuring no duplicates
/// are produced. Eliminates FieldWidgetSymbol intermediate objects for
/// simplified direct enum processing.
@lazySingleton
class SymbolicCombinationGenerator {
  /// Generates all valid field-widget-validator combinations as enum tuples.
  ///
  /// Creates a comprehensive list of enum tuples representing every valid
  /// triplet of field type, UI element, and required validators. The
  /// combinations respect UI-validator coupling rules and contain no duplicates.
  ///
  /// Returns a list of unique enum tuples covering all valid combinations
  /// according to the coupling rules.
  ///
  /// Example:
  /// ```dart
  /// final generator = SymbolicCombinationGenerator();
  /// final combinations = generator.generateAllValidEnumCombinations();
  ///
  /// // Results include combinations like:
  /// // (FieldEnum.integer, UiElementEnum.slider, [ValidatorType.numeric])
  /// // (FieldEnum.text, UiElementEnum.textField, [])
  /// // (FieldEnum.enumerated, UiElementEnum.dropdown, [ValidatorType.enumerated])
  /// ```
  List<(FieldEnum, UiElementEnum, List<ValidatorType>)>
  generateAllValidEnumCombinations() {
    final combinations = <(FieldEnum, UiElementEnum, List<ValidatorType>)>[];

    // Generate combinations for each field type
    for (final fieldType in FieldEnum.values) {
      final fieldCombinations = generateForFieldType(fieldType);
      combinations.addAll(fieldCombinations);
    }

    return combinations;
  }

  /// Generates valid combinations for a specific field type as enum tuples.
  ///
  /// Creates enum tuples for all UI elements that are compatible with the
  /// given field type, respecting coupling rules.
  ///
  /// [fieldType] The field type to generate combinations for
  ///
  /// Returns a list of enum tuples for the specified field type.
  ///
  /// Example:
  /// ```dart
  /// final generator = SymbolicCombinationGenerator();
  /// final integerCombinations = generator.generateForFieldType(FieldEnum.integer);
  ///
  /// // Results include:
  /// // (FieldEnum.integer, UiElementEnum.slider, [ValidatorType.numeric])
  /// // (FieldEnum.integer, UiElementEnum.stepper, [ValidatorType.numeric])
  /// // (FieldEnum.integer, UiElementEnum.textField, [])
  /// ```
  List<(FieldEnum, UiElementEnum, List<ValidatorType>)> generateForFieldType(
    FieldEnum fieldType,
  ) {
    final combinations = <(FieldEnum, UiElementEnum, List<ValidatorType>)>[];

    // Check each UI element for compatibility with this field type
    for (final uiElement in UiElementEnum.values) {
      if (isValidFieldUiCombination(fieldType, uiElement)) {
        final requiredValidators = UiValidatorCoupling.getRequiredValidators(
          uiElement,
        );
        combinations.add((fieldType, uiElement, requiredValidators));
      }
    }

    return combinations;
  }

  /// Checks if a field type and UI element combination is valid.
  ///
  /// Determines compatibility between field types and UI elements based on
  /// logical constraints and coupling rules. For example, boolean fields
  /// should only work with boolean UI elements, numeric fields work with
  /// numeric UI elements, etc.
  ///
  /// [fieldType] The field type to check
  /// [uiElement] The UI element to check
  ///
  /// Returns true if the combination is valid, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final generator = SymbolicCombinationGenerator();
  ///
  /// generator.isValidFieldUiCombination(FieldEnum.integer, UiElementEnum.slider); // true
  /// generator.isValidFieldUiCombination(FieldEnum.boolean, UiElementEnum.slider); // false
  /// generator.isValidFieldUiCombination(FieldEnum.text, UiElementEnum.textField); // true
  /// ```
  bool isValidFieldUiCombination(FieldEnum fieldType, UiElementEnum uiElement) {
    switch (fieldType) {
      case FieldEnum.integer:
      case FieldEnum.float:
        // Numeric fields work with numeric UI elements, text fields, and timer
        return _isNumericCompatibleUi(uiElement) ||
            _isTextCompatibleUi(uiElement) ||
            uiElement == UiElementEnum.timer;

      case FieldEnum.text:
        // Text fields work with text UI elements and search fields
        return _isTextCompatibleUi(uiElement) ||
            _isSearchCompatibleUi(uiElement);

      case FieldEnum.boolean:
        // Boolean fields work with boolean UI elements
        return _isBooleanCompatibleUi(uiElement);

      case FieldEnum.datetime:
        // DateTime fields work with date/time UI elements and text fields
        return _isDateTimeCompatibleUi(uiElement) ||
            _isTextCompatibleUi(uiElement);

      case FieldEnum.enumerated:
        // Enumerated fields work with selection UI elements
        return _isSelectionCompatibleUi(uiElement);

      case FieldEnum.dimension:
        // Dimension fields work with numeric UI elements and text fields
        return _isNumericCompatibleUi(uiElement) ||
            _isTextCompatibleUi(uiElement);

      case FieldEnum.reference:
        // Reference fields work with selection UI elements, text fields, and search fields
        return _isSelectionCompatibleUi(uiElement) ||
            _isTextCompatibleUi(uiElement) ||
            _isSearchCompatibleUi(uiElement);

      case FieldEnum.location:
        // Location fields only work with the location picker
        return uiElement == UiElementEnum.locationPicker;
    }
  }

  /// Checks if a UI element is compatible with numeric input.
  bool _isNumericCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.slider ||
        uiElement == UiElementEnum.stepper;
  }

  /// Checks if a UI element is compatible with text input.
  bool _isTextCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.textField ||
        uiElement == UiElementEnum.textArea;
  }

  /// Checks if a UI element is compatible with boolean input.
  bool _isBooleanCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.toggleSwitch ||
        uiElement == UiElementEnum.checkbox;
  }

  /// Checks if a UI element is compatible with date/time input.
  bool _isDateTimeCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.datePicker ||
        uiElement == UiElementEnum.timePicker ||
        uiElement == UiElementEnum.datetimePicker;
  }

  /// Checks if a UI element is compatible with selection input.
  bool _isSelectionCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.dropdown ||
        uiElement == UiElementEnum.radio ||
        uiElement == UiElementEnum.chips;
  }

  /// Checks if a UI element is compatible with search/autocomplete input.
  bool _isSearchCompatibleUi(UiElementEnum uiElement) {
    return uiElement == UiElementEnum.searchField;
  }

  /// Gets the total count of valid combinations without generating them all.
  ///
  /// Efficiently calculates the number of valid combinations that would be
  /// generated without actually creating the FieldWidgetSymbol instances.
  /// Useful for performance monitoring and validation.
  ///
  /// Returns the total number of valid field-UI-validator combinations.
  int getValidCombinationCount() {
    int count = 0;

    for (final fieldType in FieldEnum.values) {
      for (final uiElement in UiElementEnum.values) {
        if (isValidFieldUiCombination(fieldType, uiElement)) {
          count++;
        }
      }
    }

    return count;
  }

  /// Gets all valid UI elements for a specific field type.
  ///
  /// Returns a list of UI elements that are compatible with the given field type
  /// based on the coupling rules and logical constraints.
  ///
  /// [fieldType] The field type to get compatible UI elements for
  ///
  /// Returns a list of compatible UiElementEnum values.
  List<UiElementEnum> getValidUiElementsForField(FieldEnum fieldType) {
    final validUiElements = <UiElementEnum>[];

    for (final uiElement in UiElementEnum.values) {
      if (isValidFieldUiCombination(fieldType, uiElement)) {
        validUiElements.add(uiElement);
      }
    }

    return validUiElements;
  }

  /// Gets all valid field types for a specific UI element.
  ///
  /// Returns a list of field types that are compatible with the given UI element
  /// based on the coupling rules and logical constraints.
  ///
  /// [uiElement] The UI element to get compatible field types for
  ///
  /// Returns a list of compatible FieldEnum values.
  List<FieldEnum> getValidFieldTypesForUi(UiElementEnum uiElement) {
    final validFieldTypes = <FieldEnum>[];

    for (final fieldType in FieldEnum.values) {
      if (isValidFieldUiCombination(fieldType, uiElement)) {
        validFieldTypes.add(fieldType);
      }
    }

    return validFieldTypes;
  }
}
