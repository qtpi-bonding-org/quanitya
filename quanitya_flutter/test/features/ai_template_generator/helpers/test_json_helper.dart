/// Helper functions for creating valid test JSON structures that match the new hierarchical schema
/// 
/// This ensures all tests use the correct structure expected by our custom schema generator
/// when validated by the json_schema library.

import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';

/// Creates a complete valid JSON structure with all required top-level fields
Map<String, dynamic> createCompleteValidJson({
  Map<String, dynamic>? fontsOverride,
  Map<String, dynamic>? colorPaletteOverride,
  Map<String, dynamic>? pageTemplateOverride,
  Map<String, dynamic>? pageColorMappingsOverride,
  Map<String, dynamic>? templateOverride,
}) {
  return {
    'fonts': fontsOverride ?? createValidFonts(),
    'colorPalette': colorPaletteOverride ?? createValidColorPalette(),
    'pageTemplate': pageTemplateOverride ?? createValidPageTemplate(),
    'pageColorMappings': pageColorMappingsOverride ?? createValidPageColorMappings(),
    'template': templateOverride ?? createValidTemplate(),
  };
}

/// Creates valid fonts configuration
Map<String, dynamic> createValidFonts() {
  return {
    'titleFontFamily': 'Inter',
    'subtitleFontFamily': 'Inter',
    'bodyFontFamily': 'Inter',
    'titleWeight': 'w600',
    'subtitleWeight': 'w500',
    'bodyWeight': 'w400',
  };
}

/// Creates valid color palette
Map<String, dynamic> createValidColorPalette() {
  return {
    'colors': ['#FF6B35', '#F7931E'],
    'neutrals': ['#2C3E50', '#ECF0F1'],
  };
}

/// Creates valid page template
Map<String, dynamic> createValidPageTemplate() {
  return {
    'title': 'Test Template',
    'subtitle': 'Test subtitle',
  };
}

/// Creates valid page color mappings
Map<String, dynamic> createValidPageColorMappings() {
  return {
    'background': 'neutral2',
    'primary': 'color1',
  };
}

/// Creates valid template section
Map<String, dynamic> createValidTemplate({
  List<Map<String, dynamic>>? fields,
  List<Map<String, dynamic>>? uiColorMappings,
}) {
  return {
    'templateName': 'Test Template',
    'fields': fields ?? [createValidField(FieldEnum.text, UiElementEnum.textField)],
    'uiColorMappings': uiColorMappings ?? [],
  };
}

/// Creates a valid field for a specific field-widget combination with all required properties
Map<String, dynamic> createValidField(FieldEnum fieldType, UiElementEnum uiElement) {
  final fieldData = <String, dynamic>{
    'id': 'field1',
    'label': 'Test Field',
    'fieldType': fieldType.name,
    'uiElement': uiElement.name,
  };

  // Add required properties based on field type and UI element
  switch (fieldType) {
    case FieldEnum.integer:
    case FieldEnum.float:
      if (uiElement == UiElementEnum.slider || uiElement == UiElementEnum.stepper) {
        fieldData['min'] = 0;
        fieldData['max'] = 100;
        fieldData['step'] = 1;
      }
      break;
      
    case FieldEnum.text:
      // Text fields can have optional validation properties
      break;
      
    case FieldEnum.enumerated:
      fieldData['options'] = ['Option1', 'Option2', 'Option3'];
      break;
      
    case FieldEnum.dimension:
      fieldData['unit'] = 'kilograms';
      break;
      
    case FieldEnum.reference:
      fieldData['targetTemplateId'] = 'target-template-id';
      break;
      
    case FieldEnum.boolean:
    case FieldEnum.datetime:
    case FieldEnum.location:
    case FieldEnum.group:
      // No additional properties required
      break;

    case FieldEnum.multiEnum:
      fieldData['options'] = ['Option1', 'Option2', 'Option3'];
      break;
  }

  return fieldData;
}

/// Creates a valid JSON for a specific field-widget combination
Map<String, dynamic> createValidJsonForCombination(FieldEnum fieldType, UiElementEnum uiElement) {
  return createCompleteValidJson(
    templateOverride: createValidTemplate(
      fields: [createValidField(fieldType, uiElement)],
    ),
  );
}

/// Creates an invalid JSON for testing validation failures
Map<String, dynamic> createInvalidJsonForCombination(
  String fieldType, 
  String uiElement, {
  Map<String, dynamic>? additionalFieldData,
}) {
  final fieldData = <String, dynamic>{
    'id': 'field1',
    'label': 'Test Field',
    'fieldType': fieldType,
    'uiElement': uiElement,
  };
  
  if (additionalFieldData != null) {
    fieldData.addAll(additionalFieldData);
  }

  return createCompleteValidJson(
    templateOverride: createValidTemplate(
      fields: [fieldData],
    ),
  );
}