import 'color_role.dart';
import '../ui_element_enum.dart';

/// Maps UI elements to their required color roles for schema generation and validation.
///
/// This class serves as the single source of truth for color role requirements,
/// used by both JSON schema generation and runtime widget color validation.
class WidgetColorRoles {
  /// Map of UI elements to their required color roles
  static const Map<UiElementEnum, List<ColorRole>> requiredRoles = {
    // Slider needs primary (handle), secondary (track), and text (label)
    UiElementEnum.slider: [
      ColorRole.primary,
      ColorRole.secondary,
      ColorRole.text,
    ],

    // Text field needs background, border, and text colors
    UiElementEnum.textField: [
      ColorRole.background,
      ColorRole.border,
      ColorRole.text,
    ],

    // Text area needs background, border, and text colors
    UiElementEnum.textArea: [
      ColorRole.background,
      ColorRole.border,
      ColorRole.text,
    ],

    // Stepper needs primary (buttons), secondary (background), and text
    UiElementEnum.stepper: [
      ColorRole.primary,
      ColorRole.secondary,
      ColorRole.text,
    ],

    // Chips need primary (selected), secondary (unselected), and text
    UiElementEnum.chips: [
      ColorRole.primary,
      ColorRole.secondary,
      ColorRole.text,
    ],

    // Dropdown needs background, border, and text colors
    UiElementEnum.dropdown: [
      ColorRole.background,
      ColorRole.border,
      ColorRole.text,
    ],

    // Radio buttons need primary (selected), secondary (unselected), and text
    UiElementEnum.radio: [
      ColorRole.primary,
      ColorRole.secondary,
      ColorRole.text,
    ],

    // Switch needs primary (active) and secondary (inactive) colors
    UiElementEnum.toggleSwitch: [
      ColorRole.primary,
      ColorRole.secondary,
    ],

    // Checkbox needs primary (checked), background, and text colors
    UiElementEnum.checkbox: [
      ColorRole.primary,
      ColorRole.background,
      ColorRole.text,
    ],

    // Date picker needs primary (selection), background, and text colors
    UiElementEnum.datePicker: [
      ColorRole.primary,
      ColorRole.background,
      ColorRole.text,
    ],

    // Time picker needs primary (selection), background, and text colors
    UiElementEnum.timePicker: [
      ColorRole.primary,
      ColorRole.background,
      ColorRole.text,
    ],

    // DateTime picker needs primary (selection), background, and text colors
    UiElementEnum.datetimePicker: [
      ColorRole.primary,
      ColorRole.background,
      ColorRole.text,
    ],

    // Search field needs background, border, and text colors
    UiElementEnum.searchField: [
      ColorRole.background,
      ColorRole.border,
      ColorRole.text,
    ],

    // Location picker needs primary (pin/marker), background (map), and text
    UiElementEnum.locationPicker: [
      ColorRole.primary,
      ColorRole.background,
      ColorRole.text,
    ],

    // Timer needs primary (active), secondary (inactive), and text
    UiElementEnum.timer: [
      ColorRole.primary,
      ColorRole.secondary,
      ColorRole.text,
    ],
  };

  /// Gets required color roles for a specific UI element
  static List<ColorRole> getRequiredRoles(UiElementEnum uiElement) {
    return requiredRoles[uiElement] ?? [];
  }

  /// Validates if a UI element has defined color role requirements
  static bool hasColorRoleRequirements(UiElementEnum uiElement) {
    return requiredRoles.containsKey(uiElement) &&
        requiredRoles[uiElement]!.isNotEmpty;
  }

  /// Gets all UI elements that require a specific color role
  static List<UiElementEnum> getUiElementsRequiring(ColorRole colorRole) {
    final elements = <UiElementEnum>[];

    for (final entry in requiredRoles.entries) {
      if (entry.value.contains(colorRole)) {
        elements.add(entry.key);
      }
    }

    return elements;
  }

  /// Gets all unique color roles used across all UI elements
  static Set<ColorRole> getAllUsedColorRoles() {
    final roles = <ColorRole>{};

    for (final roleList in requiredRoles.values) {
      roles.addAll(roleList);
    }

    return roles;
  }
}
