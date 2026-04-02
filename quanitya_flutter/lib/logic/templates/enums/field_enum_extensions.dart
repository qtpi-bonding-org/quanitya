import 'package:flutter/material.dart';

import 'field_enum.dart';
import 'ui_element_enum.dart';
import '../../../support/extensions/context_extensions.dart';

/// Extension to provide user-friendly display names and icons for field types
extension FieldEnumDisplayName on FieldEnum {
  /// Returns a localized display name for the field type
  String displayName(BuildContext context) {
    return switch (this) {
      FieldEnum.integer => context.l10n.fieldTypeNumber,
      FieldEnum.float => context.l10n.fieldTypeDecimal,
      FieldEnum.text => context.l10n.fieldTypeText,
      FieldEnum.boolean => context.l10n.fieldTypeToggle,
      FieldEnum.datetime => context.l10n.fieldTypeDate,
      FieldEnum.enumerated => context.l10n.fieldTypeChoice,
      FieldEnum.dimension => context.l10n.fieldTypeMeasurement,
      FieldEnum.reference => context.l10n.fieldTypeReference,
      FieldEnum.location => context.l10n.fieldTypeLocation,
      FieldEnum.group => context.l10n.fieldTypeGroup,
      FieldEnum.multiEnum => context.l10n.fieldTypeMultiSelect,
    };
  }

  /// Returns the icon representing this field type
  IconData get icon {
    return switch (this) {
      FieldEnum.integer => Icons.numbers,
      FieldEnum.float => Icons.numbers,
      FieldEnum.text => Icons.text_fields,
      FieldEnum.boolean => Icons.toggle_on,
      FieldEnum.datetime => Icons.calendar_today,
      FieldEnum.enumerated => Icons.list,
      FieldEnum.dimension => Icons.straighten,
      FieldEnum.reference => Icons.link,
      FieldEnum.location => Icons.location_on,
      FieldEnum.group => Icons.dashboard,
      FieldEnum.multiEnum => Icons.checklist,
    };
  }
}

/// Extension to provide localized display names for UI element types
extension UiElementEnumDisplayName on UiElementEnum {
  /// Returns a localized display name for the UI element type
  String displayName(BuildContext context) {
    return switch (this) {
      UiElementEnum.slider => context.l10n.widgetSlider,
      UiElementEnum.stepper => context.l10n.widgetStepper,
      UiElementEnum.textField => context.l10n.widgetTextField,
      UiElementEnum.textArea => context.l10n.widgetTextArea,
      UiElementEnum.dropdown => context.l10n.widgetDropdown,
      UiElementEnum.radio => context.l10n.widgetRadio,
      UiElementEnum.chips => context.l10n.widgetChips,
      UiElementEnum.toggleSwitch => context.l10n.widgetToggleSwitch,
      UiElementEnum.checkbox => context.l10n.widgetCheckbox,
      UiElementEnum.datePicker => context.l10n.widgetDatePicker,
      UiElementEnum.timePicker => context.l10n.widgetTimePicker,
      UiElementEnum.datetimePicker => context.l10n.widgetDatetimePicker,
      UiElementEnum.searchField => context.l10n.widgetSearchField,
      UiElementEnum.locationPicker => context.l10n.widgetLocationPicker,
      UiElementEnum.timer => context.l10n.widgetTimer,
    };
  }
}
