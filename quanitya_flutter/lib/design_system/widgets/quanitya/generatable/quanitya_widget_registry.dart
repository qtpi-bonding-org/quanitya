import 'package:flutter_colorable/flutter_colorable.dart';

/// Registry of all Quanitya widget schemas for AI schema generation.
///
/// Contains [ColorableWidgetSchema] definitions for all widgets annotated
/// with @ColorableWidget. Used by [UnifiedSchemaGenerator] to produce
/// JSON schemas for AI color selection.
///
/// Note: These schemas mirror the generated _$*Schema constants but are
/// defined here to be publicly accessible. When adding new widgets,
/// add their schema here as well.
///
/// Example:
/// ```dart
/// final schema = QuanityaWidgetRegistry.generateAiSchema(
///   availableColors: ['color1', 'color2', 'neutral1'],
/// );
/// ```
class QuanityaWidgetRegistry {
  QuanityaWidgetRegistry._();

  /// All registered widget schemas, keyed by UiElementEnum name.
  /// This allows direct lookup using field.uiElement.name without conversion.
  static final schemas = <String, ColorableWidgetSchema>{
    'button': const ColorableWidgetSchema(
      widgetKey: 'button',
      properties: [
        ColorableProperty(name: 'backgroundColor'),
        ColorableProperty(name: 'foregroundColor'),
      ],
    ),
    'checkbox': const ColorableWidgetSchema(
      widgetKey: 'checkbox',
      properties: [
        ColorableProperty(name: 'activeColor'),
        ColorableProperty(name: 'checkColor'),
        ColorableProperty(name: 'borderColor'),
      ],
    ),
    'chips': const ColorableWidgetSchema(
      widgetKey: 'chips',
      properties: [
        ColorableProperty(name: 'selectedColor'),
        ColorableProperty(name: 'unselectedColor'),
        ColorableProperty(name: 'labelColor'),
      ],
    ),
    'datePicker': const ColorableWidgetSchema(
      widgetKey: 'datePicker',
      properties: [
        ColorableProperty(name: 'primaryColor'),
        ColorableProperty(name: 'backgroundColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'fillColor'),
      ],
    ),
    'datetimePicker': const ColorableWidgetSchema(
      widgetKey: 'datetimePicker',
      properties: [
        ColorableProperty(name: 'primaryColor'),
        ColorableProperty(name: 'backgroundColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'fillColor'),
      ],
    ),
    'dropdown': const ColorableWidgetSchema(
      widgetKey: 'dropdown',
      properties: [
        ColorableProperty(name: 'dropdownColor'),
        ColorableProperty(name: 'fillColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'iconColor'),
      ],
    ),
    'radio': const ColorableWidgetSchema(
      widgetKey: 'radio',
      properties: [
        ColorableProperty(name: 'activeColor'),
        ColorableProperty(name: 'inactiveColor'),
      ],
    ),
    'searchField': const ColorableWidgetSchema(
      widgetKey: 'searchField',
      properties: [
        ColorableProperty(name: 'cursorColor'),
        ColorableProperty(name: 'fillColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'focusedBorderColor'),
      ],
    ),
    'slider': const ColorableWidgetSchema(
      widgetKey: 'slider',
      properties: [
        ColorableProperty(name: 'activeColor'),
        ColorableProperty(name: 'inactiveColor'),
        ColorableProperty(name: 'thumbColor'),
      ],
    ),
    'stepper': const ColorableWidgetSchema(
      widgetKey: 'stepper',
      properties: [
        ColorableProperty(name: 'buttonColor'),
        ColorableProperty(name: 'iconColor'),
        ColorableProperty(name: 'valueColor'),
      ],
    ),
    'textField': const ColorableWidgetSchema(
      widgetKey: 'textField',
      properties: [
        ColorableProperty(name: 'cursorColor'),
        ColorableProperty(name: 'fillColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'focusedBorderColor'),
        ColorableProperty(name: 'errorBorderColor'),
      ],
    ),
    'textArea': const ColorableWidgetSchema(
      widgetKey: 'textArea',
      properties: [
        ColorableProperty(name: 'cursorColor'),
        ColorableProperty(name: 'fillColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'focusedBorderColor'),
        ColorableProperty(name: 'errorBorderColor'),
      ],
    ),
    'timePicker': const ColorableWidgetSchema(
      widgetKey: 'timePicker',
      properties: [
        ColorableProperty(name: 'primaryColor'),
        ColorableProperty(name: 'backgroundColor'),
        ColorableProperty(name: 'borderColor'),
        ColorableProperty(name: 'fillColor'),
      ],
    ),
    'toggleSwitch': const ColorableWidgetSchema(
      widgetKey: 'toggleSwitch',
      properties: [
        ColorableProperty(name: 'activeThumbColor'),
        ColorableProperty(name: 'activeTrackColor'),
        ColorableProperty(name: 'inactiveThumbColor'),
        ColorableProperty(name: 'inactiveTrackColor'),
      ],
    ),
  };

  /// Get schema for a specific widget type.
  static ColorableWidgetSchema? getSchema(String widgetType) =>
      schemas[widgetType];

  /// Get all registered widget types.
  static List<String> get widgetTypes => schemas.keys.toList();

  /// Get colorable property names for a widget type.
  static List<String>? getColorableProperties(String widgetType) =>
      schemas[widgetType]?.propertyNames;

  /// Generate combined JSON schema for AI consumption.
  ///
  /// Returns a map where each key is a widget type and the value
  /// is its JSON schema with color enum constraints.
  static Map<String, dynamic> generateAiSchema({
    List<String> availableColors = const [
      'color1',
      'color2',
      'color3',
      'neutral1',
      'neutral2',
    ],
  }) {
    return {
      for (final entry in schemas.entries)
        entry.key: entry.value.toJsonSchema(availableColors: availableColors),
    };
  }

  /// Generate a flat list of all colorable properties across all widgets.
  ///
  /// Useful for validation and debugging.
  static List<Map<String, dynamic>> getAllColorableProperties() {
    return [
      for (final entry in schemas.entries)
        for (final prop in entry.value.properties)
          {
            'widget': entry.key,
            'property': prop.name,
            if (prop.description != null) 'description': prop.description,
            if (prop.defaultColor != null) 'default': prop.defaultColor,
          },
    ];
  }
}
