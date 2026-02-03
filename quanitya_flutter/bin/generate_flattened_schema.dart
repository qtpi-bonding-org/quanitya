import 'dart:convert';
import 'dart:io';

/// Script to generate the FLATTENED JSON schema for Gemini API compatibility.
/// 
/// This produces a schema with reduced nesting depth (4 levels instead of 6+)
/// by using a single flat oneOf pattern instead of grouping by field type.
/// 
/// Output: generated_schema_flattened_new.json
void main() async {
  try {
    print('🔧 Generating FLATTENED JSON schema...');
    
    // Generate the flattened schema
    final schema = generateFlattenedSchema();
    
    // Convert to pretty-printed JSON
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(schema);
    
    // Write to file
    final file = File('generated_schema_flattened_new.json');
    await file.writeAsString(jsonString);
    
    print('✅ Flattened schema generated successfully!');
    print('📄 Output file: ${file.path}');
    print('📊 Schema size: ${jsonString.length} characters');
    
    // Print stats
    final stats = _analyzeSchema(schema);
    print('📈 Schema statistics:');
    print('   - Total properties: ${stats['properties']}');
    print('   - Enum values: ${stats['enums']}');
    print('   - OneOf patterns: ${stats['oneOfs']}');
    print('   - Nesting depth: ${stats['depth']}');
    
    // Compare with nested version
    print('\n📊 Comparison with nested version:');
    print('   - Nested: ~6 levels, ~29,813 chars');
    print('   - Flattened: ${stats['depth']} levels, ${jsonString.length} chars');
    print('   - Reduction: ${((29813 - jsonString.length) / 29813 * 100).toStringAsFixed(1)}% smaller');
    
  } catch (e, stackTrace) {
    print('❌ Error generating schema: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Generates the FLATTENED JSON schema
/// 
/// Key difference from nested version:
/// - Uses `fieldCombination` (singular) with flat oneOf
/// - All combinations in single list, not grouped by field type
/// - Reduces nesting from 6+ levels to 4 levels
Map<String, dynamic> generateFlattenedSchema() {
  return {
    '\$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'fieldCombination': _generateFlatFieldCombinations(),
      'colorPalette': _generateColorPaletteSchema(),
      'fontConfiguration': _generateFontConfigurationSchema(),
    },
    'additionalProperties': false,
  };
}

/// Generates FLAT field combinations - single oneOf with all combinations
Map<String, dynamic> _generateFlatFieldCombinations() {
  return {
    'oneOf': [
      // Integer combinations
      _combo('integer', 'slider', ['numeric']),
      _combo('integer', 'stepper', ['numeric']),
      _combo('integer', 'textField', []),
      _combo('integer', 'textArea', []),
      
      // Float combinations
      _combo('float', 'slider', ['numeric']),
      _combo('float', 'stepper', ['numeric']),
      _combo('float', 'textField', []),
      _combo('float', 'textArea', []),
      
      // Text combinations
      _combo('text', 'textField', []),
      _combo('text', 'textArea', []),
      
      // Boolean combinations
      _combo('boolean', 'toggleSwitch', []),
      _combo('boolean', 'checkbox', []),
      
      // DateTime combinations
      _combo('datetime', 'datePicker', []),
      _combo('datetime', 'timePicker', []),
      _combo('datetime', 'textField', []),
      _combo('datetime', 'textArea', []),
      
      // Enumerated combinations
      _combo('enumerated', 'dropdown', ['enumerated']),
      _combo('enumerated', 'radio', ['enumerated']),
      _combo('enumerated', 'chips', ['enumerated']),
      
      // Dimension combinations
      _combo('dimension', 'slider', ['numeric']),
      _combo('dimension', 'stepper', ['numeric']),
      _combo('dimension', 'textField', []),
      _combo('dimension', 'textArea', []),
      
      // Reference combinations
      _combo('reference', 'dropdown', ['enumerated']),
      _combo('reference', 'radio', ['enumerated']),
      _combo('reference', 'chips', ['enumerated']),
      _combo('reference', 'textField', []),
      _combo('reference', 'textArea', []),
    ],
  };
}

/// Helper to create a single combination schema object
Map<String, dynamic> _combo(String fieldType, String uiElement, List<String> validators) {
  return {
    'type': 'object',
    'properties': {
      'fieldType': {'type': 'string', 'const': fieldType},
      'uiElement': {'type': 'string', 'const': uiElement},
      'requiredValidators': {
        'type': 'array',
        'items': {'type': 'string', 'enum': validators},
        'minItems': validators.length,
        'maxItems': validators.length,
      },
    },
    'required': ['fieldType', 'uiElement', 'requiredValidators'],
    'additionalProperties': false,
  };
}

/// Generates color palette schema (unchanged from nested version)
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

/// Generates font configuration schema (unchanged from nested version)
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
