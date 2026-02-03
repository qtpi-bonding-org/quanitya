#!/usr/bin/env dart

import 'dart:convert';

void main() {
  print('🔍 Showing the translated schema from standalone pipeline...');
  
  // This is the simplified schema from the standalone pipeline
  final originalSchema = {
    '\$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'templateName': {
        'type': 'string',
        'description': 'Name of the template',
      },
      'fields': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'fieldType': {
              'enum': ['text', 'number', 'boolean', 'date'],
              'description': 'Type of field from foundation enums',
            },
            'widgetType': {
              'enum': ['textField', 'textArea', 'slider', 'stepper', 'checkbox', 'datePicker'],
              'description': 'Widget type from foundation enums',
            },
            'label': {
              'type': 'string',
              'description': 'Field label',
            },
          },
          'required': ['fieldType', 'widgetType', 'label'],
          'additionalProperties': false,
        },
        'minItems': 1,
        'maxItems': 10,
      },
      'colorPalette': {
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {
              'type': 'string',
              'pattern': r'^#[0-9A-Fa-f]{6}$',
            },
            'minItems': 2,
            'maxItems': 4,
            'description': 'Main colors (color1-color4)',
          },
          'neutrals': {
            'type': 'array',
            'items': {
              'type': 'string',
              'pattern': r'^#[0-9A-Fa-f]{6}$',
            },
            'minItems': 2,
            'maxItems': 3,
            'description': 'Neutral colors (neutral1-neutral3)',
          },
        },
        'required': ['colors', 'neutrals'],
        'additionalProperties': false,
      },
      'fontConfiguration': {
        'type': 'object',
        'properties': {
          'titleWeight': {
            'type': 'integer',
            'minimum': 100,
            'maximum': 900,
            'multipleOf': 100,
            'default': 600,
            'description': 'Font weight for titles',
          },
          'bodyWeight': {
            'type': 'integer',
            'minimum': 100,
            'maximum': 900,
            'multipleOf': 100,
            'default': 400,
            'description': 'Font weight for body text',
          },
        },
        'additionalProperties': false,
      },
    },
    'required': ['templateName', 'fields', 'colorPalette', 'fontConfiguration'],
    'additionalProperties': false,
  };
  
  print('\n📋 ORIGINAL SCHEMA:');
  print('=' * 60);
  print(JsonEncoder.withIndent('  ').convert(originalSchema));
  print('=' * 60);
  
  // Apply the same translation logic as GeminiSchemaTranslator
  final translatedSchema = _translateForGemini(originalSchema);
  
  print('\n🔄 TRANSLATED SCHEMA:');
  print('=' * 60);
  print(JsonEncoder.withIndent('  ').convert(translatedSchema));
  print('=' * 60);
  
  // Check nesting depth
  int maxDepth = _calculateDepth(translatedSchema);
  print('\n📊 NESTING DEPTH: $maxDepth levels');
  
  if (maxDepth > 10) {
    print('❌ EXCESSIVE NESTING DETECTED!');
  } else {
    print('✅ Nesting depth looks reasonable');
  }
}

Map<String, dynamic> _translateForGemini(Map<String, dynamic> jsonSchema) {
  final translated = <String, dynamic>{};
  
  for (final entry in jsonSchema.entries) {
    switch (entry.key) {
      case 'type':
      case 'description':
      case 'title':
      case 'minimum':
      case 'maximum':
      case 'minItems':
      case 'maxItems':
      case 'required':
      case 'additionalProperties':
      case 'format':
      case 'enum':
      case 'default':
        translated[entry.key] = entry.value;
        break;
        
      case 'properties':
        translated['properties'] = _translateProperties(entry.value as Map<String, dynamic>);
        break;
        
      case 'items':
        translated['items'] = _translateForGemini(entry.value as Map<String, dynamic>);
        break;
        
      case 'multipleOf':
        // Convert multipleOf to enum
        final multipleOf = entry.value as int;
        final min = jsonSchema['minimum'] as int? ?? 0;
        final max = jsonSchema['maximum'] as int? ?? 1000;
        
        final enumValues = <int>[];
        for (int i = min; i <= max; i += multipleOf) {
          enumValues.add(i);
        }
        translated['enum'] = enumValues;
        break;
        
      case 'pattern':
        // Convert pattern to description
        final pattern = entry.value as String;
        final patternDesc = pattern == r'^#[0-9A-Fa-f]{6}$' 
            ? 'Must be 6-digit hex color format (e.g., #FF0000)'
            : 'Must match pattern: $pattern';
        
        final existingDesc = jsonSchema['description'] as String?;
        translated['description'] = existingDesc != null 
            ? '$existingDesc. $patternDesc' 
            : patternDesc;
        break;
        
      case r'$schema':
        // Skip
        break;
        
      default:
        translated[entry.key] = entry.value;
    }
  }
  
  return translated;
}

Map<String, dynamic> _translateProperties(Map<String, dynamic> properties) {
  final translated = <String, dynamic>{};
  for (final entry in properties.entries) {
    translated[entry.key] = _translateForGemini(entry.value as Map<String, dynamic>);
  }
  return translated;
}

int _calculateDepth(dynamic obj, [int currentDepth = 0]) {
  if (obj is Map) {
    int maxChildDepth = currentDepth;
    for (final value in obj.values) {
      final childDepth = _calculateDepth(value, currentDepth + 1);
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth;
  } else if (obj is List) {
    int maxChildDepth = currentDepth;
    for (final item in obj) {
      final childDepth = _calculateDepth(item, currentDepth + 1);
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth;
  } else {
    return currentDepth;
  }
}