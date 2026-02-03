import 'dart:convert';
import 'dart:io';

/// Simple script to generate the JSON schema without Flutter dependencies.
/// 
/// This manually creates the schema structure based on the enums and logic
/// from the Flutter code, but without importing Flutter packages.
void main() async {
  try {
    print('🔧 Generating JSON schema from enum definitions...');
    
    // Generate the complete schema manually
    final schema = generateCompleteSchema();
    
    // Convert to pretty-printed JSON
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(schema);
    
    // Write to file
    final file = File('generated_schema_complete.json');
    await file.writeAsString(jsonString);
    
    print('✅ Schema generated successfully!');
    print('📄 Output file: ${file.path}');
    print('📊 Schema size: ${jsonString.length} characters');
    
    // Print some stats
    final stats = _analyzeSchema(schema);
    print('📈 Schema statistics:');
    print('   - Total properties: ${stats['properties']}');
    print('   - Enum values: ${stats['enums']}');
    print('   - OneOf patterns: ${stats['oneOfs']}');
    print('   - Nesting depth: ${stats['depth']}');
    
  } catch (e, stackTrace) {
    print('❌ Error generating schema: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Generates the complete JSON schema based on the Flutter/Dart enums
Map<String, dynamic> generateCompleteSchema() {
  return {
    '\$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'fields': _generateFieldSchemas(),
      'colorPalette': _generateColorPaletteSchema(),
      'fontConfiguration': _generateFontConfigurationSchema(),
    },
    'additionalProperties': false,
  };
}

/// Generates field schemas with oneOf patterns for valid combinations
Map<String, dynamic> _generateFieldSchemas() {
  return {
    'type': 'object',
    'properties': {
      'fieldCombinations': {
        'type': 'object',
        'properties': {
          // Integer field combinations
          'integer': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'integer'},
                  'uiElement': {'type': 'string', 'const': 'slider'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'integer'},
                  'uiElement': {'type': 'string', 'const': 'stepper'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'integer'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'integer'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Float field combinations
          'float': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'float'},
                  'uiElement': {'type': 'string', 'const': 'slider'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'float'},
                  'uiElement': {'type': 'string', 'const': 'stepper'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'float'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'float'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Text field combinations
          'text': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'text'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'text'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Boolean field combinations
          'boolean': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'boolean'},
                  'uiElement': {'type': 'string', 'const': 'toggleSwitch'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'boolean'},
                  'uiElement': {'type': 'string', 'const': 'checkbox'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // DateTime field combinations
          'datetime': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'datetime'},
                  'uiElement': {'type': 'string', 'const': 'datePicker'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'datetime'},
                  'uiElement': {'type': 'string', 'const': 'timePicker'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'datetime'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'datetime'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Enumerated field combinations
          'enumerated': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'enumerated'},
                  'uiElement': {'type': 'string', 'const': 'dropdown'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'enumerated'},
                  'uiElement': {'type': 'string', 'const': 'radio'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'enumerated'},
                  'uiElement': {'type': 'string', 'const': 'chips'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Dimension field combinations
          'dimension': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'dimension'},
                  'uiElement': {'type': 'string', 'const': 'slider'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'dimension'},
                  'uiElement': {'type': 'string', 'const': 'stepper'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['numeric']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'dimension'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'dimension'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
          
          // Reference field combinations
          'reference': {
            'oneOf': [
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'reference'},
                  'uiElement': {'type': 'string', 'const': 'dropdown'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'reference'},
                  'uiElement': {'type': 'string', 'const': 'radio'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'reference'},
                  'uiElement': {'type': 'string', 'const': 'chips'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': ['enumerated']},
                    'minItems': 1,
                    'maxItems': 1,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'reference'},
                  'uiElement': {'type': 'string', 'const': 'textField'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
              {
                'type': 'object',
                'properties': {
                  'fieldType': {'type': 'string', 'const': 'reference'},
                  'uiElement': {'type': 'string', 'const': 'textArea'},
                  'requiredValidators': {
                    'type': 'array',
                    'items': {'type': 'string', 'enum': []},
                    'minItems': 0,
                    'maxItems': 0,
                  },
                },
                'required': ['fieldType', 'uiElement', 'requiredValidators'],
                'additionalProperties': false,
              },
            ],
          },
        },
        'additionalProperties': false,
      },
    },
    'additionalProperties': false,
  };
}

/// Generates color palette schema
Map<String, dynamic> _generateColorPaletteSchema() {
  return {
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
  };
}

/// Generates font configuration schema
Map<String, dynamic> _generateFontConfigurationSchema() {
  return {
    'type': 'object',
    'properties': {
      'titleFontFamily': {
        'type': ['string', 'null'],
        'description': 'Font family for titles',
      },
      'subtitleFontFamily': {
        'type': ['string', 'null'],
        'description': 'Font family for subtitles',
      },
      'bodyFontFamily': {
        'type': ['string', 'null'],
        'description': 'Font family for body text',
      },
      'titleWeight': {
        'type': 'integer',
        'minimum': 100,
        'maximum': 900,
        'multipleOf': 100,
        'default': 600,
        'description': 'Font weight for titles',
      },
      'subtitleWeight': {
        'type': 'integer',
        'minimum': 100,
        'maximum': 900,
        'multipleOf': 100,
        'default': 400,
        'description': 'Font weight for subtitles',
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
  };
}

/// Analyzes the schema structure to provide statistics
Map<String, int> _analyzeSchema(Map<String, dynamic> schema) {
  int propertyCount = 0;
  int enumCount = 0;
  int oneOfCount = 0;
  int maxDepth = 0;
  
  void analyzeObject(Map<String, dynamic> obj, int depth) {
    maxDepth = depth > maxDepth ? depth : maxDepth;
    
    for (final entry in obj.entries) {
      final value = entry.value;
      
      if (entry.key == 'properties' && value is Map<String, dynamic>) {
        propertyCount += value.length;
        for (final prop in value.values) {
          if (prop is Map<String, dynamic>) {
            analyzeObject(prop, depth + 1);
          }
        }
      } else if (entry.key == 'enum' && value is List) {
        enumCount += value.length;
      } else if (entry.key == 'oneOf' && value is List) {
        oneOfCount += value.length;
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            analyzeObject(item, depth + 1);
          }
        }
      } else if (entry.key == 'items' && value is Map<String, dynamic>) {
        analyzeObject(value, depth + 1);
      } else if (value is Map<String, dynamic>) {
        analyzeObject(value, depth + 1);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            analyzeObject(item, depth + 1);
          }
        }
      }
    }
  }
  
  analyzeObject(schema, 0);
  
  return {
    'properties': propertyCount,
    'enums': enumCount,
    'oneOfs': oneOfCount,
    'depth': maxDepth,
  };
}