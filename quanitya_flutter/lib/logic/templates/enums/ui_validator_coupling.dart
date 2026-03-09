import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';

/// System that enforces which UI elements require which validators.
///
/// This class provides compile-time safety by defining valid UI-validator
/// combinations and preventing invalid pairings that could lead to runtime errors.
class UiValidatorCoupling {
  /// Map defining which validators are required for each UI element type.
  ///
  /// This serves as the single source of truth for UI-validator relationships:
  /// - Numeric UI elements (slider, stepper) MUST have numeric validators
  /// - Selection UI elements (dropdown, radio, chips) MUST have enumerated validators
  /// - Text UI elements (textField, textArea) CAN have text validators (optional)
  /// - Boolean UI elements (toggleSwitch, checkbox) don't need validators
  /// - Date/time UI elements (datePicker, timePicker) don't need validators
  static const Map<UiElementEnum, List<ValidatorType>> requiredValidators = {
    // Numeric UI elements MUST have numeric validators with min/max/step
    UiElementEnum.slider: [ValidatorType.numeric],
    UiElementEnum.stepper: [ValidatorType.numeric],

    // Selection UI elements MUST have enumerated validators with options
    UiElementEnum.dropdown: [ValidatorType.enumerated],
    UiElementEnum.radio: [ValidatorType.enumerated],
    UiElementEnum.chips: [ValidatorType.enumerated],

    // Text UI elements CAN have text validators (length/pattern constraints)
    UiElementEnum.textField: [], // Optional text validators
    UiElementEnum.textArea: [], // Optional text validators
    // Boolean UI elements don't need validators
    UiElementEnum.toggleSwitch: [],
    UiElementEnum.checkbox: [],

    // Date/time UI elements don't need validators
    UiElementEnum.datePicker: [],
    UiElementEnum.timePicker: [],
    UiElementEnum.datetimePicker: [],

    // Search field doesn't need validators
    UiElementEnum.searchField: [],

    // Location picker doesn't need validators
    UiElementEnum.locationPicker: [],

    // Timer doesn't need validators
    UiElementEnum.timer: [],
  };

  /// Map defining which validators are allowed (but not required) for each UI element.
  ///
  /// This enables optional validators while maintaining type safety.
  static const Map<UiElementEnum, List<ValidatorType>> allowedValidators = {
    // Numeric UI elements can have numeric validators
    UiElementEnum.slider: [
      ValidatorType.numeric,
      ValidatorType.dimension,
      ValidatorType.optional,
    ],
    UiElementEnum.stepper: [
      ValidatorType.numeric,
      ValidatorType.dimension,
      ValidatorType.optional,
    ],

    // Selection UI elements can have enumerated validators
    UiElementEnum.dropdown: [
      ValidatorType.enumerated,
      ValidatorType.reference,
      ValidatorType.optional,
    ],
    UiElementEnum.radio: [ValidatorType.enumerated, ValidatorType.optional],
    UiElementEnum.chips: [ValidatorType.enumerated, ValidatorType.optional],

    // Text UI elements can have text validators
    UiElementEnum.textField: [
      ValidatorType.text,
      ValidatorType.dimension,
      ValidatorType.reference,
      ValidatorType.optional,
    ],
    UiElementEnum.textArea: [ValidatorType.text, ValidatorType.optional],

    // Boolean UI elements can only have optional validators
    UiElementEnum.toggleSwitch: [ValidatorType.optional],
    UiElementEnum.checkbox: [ValidatorType.optional],

    // Date/time UI elements can only have optional validators
    UiElementEnum.datePicker: [ValidatorType.optional],
    UiElementEnum.timePicker: [ValidatorType.optional],
    UiElementEnum.datetimePicker: [ValidatorType.optional],

    // Search field can have text and optional validators
    UiElementEnum.searchField: [ValidatorType.text, ValidatorType.optional],

    // Location picker can only have optional validators
    UiElementEnum.locationPicker: [ValidatorType.optional],

    // Timer can only have optional validators
    UiElementEnum.timer: [ValidatorType.optional],
  };

  /// Checks if a UI element and validator type combination is valid.
  ///
  /// A combination is valid if the validator type is in the allowed list
  /// for the given UI element.
  ///
  /// Example:
  /// ```dart
  /// // Valid combinations
  /// UiValidatorCoupling.isValidCombination(UiElementEnum.slider, ValidatorType.numeric); // true
  /// UiValidatorCoupling.isValidCombination(UiElementEnum.dropdown, ValidatorType.enumerated); // true
  /// UiValidatorCoupling.isValidCombination(UiElementEnum.textField, ValidatorType.text); // true
  ///
  /// // Invalid combinations
  /// UiValidatorCoupling.isValidCombination(UiElementEnum.slider, ValidatorType.text); // false
  /// UiValidatorCoupling.isValidCombination(UiElementEnum.toggleSwitch, ValidatorType.numeric); // false
  /// ```
  static bool isValidCombination(
    UiElementEnum uiElement,
    ValidatorType validatorType,
  ) {
    final allowed = allowedValidators[uiElement] ?? [];
    return allowed.contains(validatorType);
  }

  /// Returns the list of required validators for a given UI element.
  ///
  /// These validators MUST be present for the UI element to function correctly.
  /// For example, sliders require numeric validators to define min/max/step values.
  ///
  /// Example:
  /// ```dart
  /// final sliderValidators = UiValidatorCoupling.getRequiredValidators(UiElementEnum.slider);
  /// // Returns: [ValidatorType.numeric]
  ///
  /// final textFieldValidators = UiValidatorCoupling.getRequiredValidators(UiElementEnum.textField);
  /// // Returns: [] (no required validators)
  /// ```
  static List<ValidatorType> getRequiredValidators(UiElementEnum uiElement) {
    return requiredValidators[uiElement] ?? [];
  }

  /// Returns the list of allowed validators for a given UI element.
  ///
  /// These validators CAN be used with the UI element, including both
  /// required and optional validators.
  ///
  /// Example:
  /// ```dart
  /// final sliderValidators = UiValidatorCoupling.getAllowedValidators(UiElementEnum.slider);
  /// // Returns: [ValidatorType.numeric, ValidatorType.optional]
  /// ```
  static List<ValidatorType> getAllowedValidators(UiElementEnum uiElement) {
    return allowedValidators[uiElement] ?? [];
  }

  /// Checks if a UI element requires any validators.
  ///
  /// Returns true if the UI element has required validators, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// UiValidatorCoupling.requiresValidators(UiElementEnum.slider); // true
  /// UiValidatorCoupling.requiresValidators(UiElementEnum.toggleSwitch); // false
  /// ```
  static bool requiresValidators(UiElementEnum uiElement) {
    final required = getRequiredValidators(uiElement);
    return required.isNotEmpty;
  }

  /// Returns all UI elements that require a specific validator type.
  ///
  /// Useful for understanding which UI elements depend on a particular
  /// validator type.
  ///
  /// Example:
  /// ```dart
  /// final numericElements = UiValidatorCoupling.getUiElementsRequiring(ValidatorType.numeric);
  /// // Returns: [UiElementEnum.slider, UiElementEnum.stepper]
  /// ```
  static List<UiElementEnum> getUiElementsRequiring(
    ValidatorType validatorType,
  ) {
    final result = <UiElementEnum>[];

    for (final entry in requiredValidators.entries) {
      if (entry.value.contains(validatorType)) {
        result.add(entry.key);
      }
    }

    return result;
  }

  /// Returns all UI elements that allow a specific validator type.
  ///
  /// This includes both required and optional usage of the validator type.
  ///
  /// Example:
  /// ```dart
  /// final optionalElements = UiValidatorCoupling.getUiElementsAllowing(ValidatorType.optional);
  /// // Returns: [UiElementEnum.slider, UiElementEnum.stepper, UiElementEnum.textField, ...]
  /// ```
  static List<UiElementEnum> getUiElementsAllowing(
    ValidatorType validatorType,
  ) {
    final result = <UiElementEnum>[];

    for (final entry in allowedValidators.entries) {
      if (entry.value.contains(validatorType)) {
        result.add(entry.key);
      }
    }

    return result;
  }

  /// Validates that all required validators are present for a UI element.
  ///
  /// Returns true if all required validators are present in the provided list,
  /// false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final validators = [ValidatorType.numeric];
  /// UiValidatorCoupling.hasAllRequiredValidators(UiElementEnum.slider, validators); // true
  ///
  /// final emptyValidators = &lt;ValidatorType&gt;[];
  /// UiValidatorCoupling.hasAllRequiredValidators(UiElementEnum.slider, emptyValidators); // false
  /// ```
  static bool hasAllRequiredValidators(
    UiElementEnum uiElement,
    List<ValidatorType> validators,
  ) {
    final required = getRequiredValidators(uiElement);

    for (final requiredValidator in required) {
      if (!validators.contains(requiredValidator)) {
        return false;
      }
    }

    return true;
  }

  /// Validates that all provided validators are allowed for a UI element.
  ///
  /// Returns true if all validators in the list are allowed for the UI element,
  /// false if any validator is not allowed.
  ///
  /// Example:
  /// ```dart
  /// final validators = [ValidatorType.numeric, ValidatorType.optional];
  /// UiValidatorCoupling.areAllValidatorsAllowed(UiElementEnum.slider, validators); // true
  ///
  /// final invalidValidators = [ValidatorType.text];
  /// UiValidatorCoupling.areAllValidatorsAllowed(UiElementEnum.slider, invalidValidators); // false
  /// ```
  static bool areAllValidatorsAllowed(
    UiElementEnum uiElement,
    List<ValidatorType> validators,
  ) {
    final allowed = getAllowedValidators(uiElement);

    for (final validator in validators) {
      if (!allowed.contains(validator)) {
        return false;
      }
    }

    return true;
  }
}
