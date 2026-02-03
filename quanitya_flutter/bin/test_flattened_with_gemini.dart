import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Complete test script that:
/// 1. Generates the flattened schema
/// 2. Tests it with Gemini API
/// 3. Reports success/failure
/// 
/// Run with: dart run bin/test_flattened_with_gemini.dart
void main() async {
  try {
    print('=' * 60);
    print('🧪 FLATTENED SCHEMA GEMINI TEST');
    print('=' * 60);
    
    // Step 1: Load API key
    final apiKey = await _loadApiKey();
    print('✅ API key loaded');
    
    // Step 2: Generate flattened schema
    print('\n📝 Generating flattened schema...');
    final schema = _generateFlattenedSchema();
    final schemaJson = const JsonEncoder.withIndent('  ').convert(schema);
    
    // Save for reference
    await File('generated_schema_flattened_test.json').writeAsString(schemaJson);
    
    // Analyze
    final stats = _analyzeSchema(schema);
    print('📊 Schema stats:');
    print('   - Size: ${schemaJson.length} characters');
    print('   - Properties: ${stats['properties']}');
    print('   - OneOf options: ${stats['oneOfs']}');
    print('   - Nesting depth: ${stats['depth']} levels');
    
    // Step 3: Test with Gemini
    print('\n🚀 Testing with Gemini API...');
    final result = await _testWithGemini(apiKey, schema);
    
    if (result != null) {
      print('\n' + '=' * 60);
      print('✅ SUCCESS! Flattened schema works with Gemini!');
      print('=' * 60);
      print('\n📝 Generated response:');
      print(const JsonEncoder.withIndent('  ').convert(result));
      
      // Validate the response structure
      print('\n🔍 Validating response structure...');
      _validateResponse(result);
      
      print('\n🎯 CONCLUSION: Schema flattening approach is VIABLE');
      print('   Next step: Update all tests to use flattened structure');
    } else {
      print('\n' + '=' * 60);
      print('❌ FAILED: Schema still has issues with Gemini');
      print('=' * 60);
      exit(1);
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<String> _loadApiKey() async {
  final envFile = File('.env');
  if (!await envFile.exists()) {
    throw Exception('.env file not found');
  }
  
  final content = await envFile.readAsString();
  for (final line in content.split('\n')) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      final key = line.substring('GEMINI_API_KEY='.length).trim();
      if (key.isNotEmpty) return key;
    }
  }
  
  throw Exception('GEMINI_API_KEY not found in .env');
}

Map<String, dynamic> _generateFlattenedSchema() {
  return {
    '\$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'fieldCombination': {
        'oneOf': [
          // Integer
          _combo('integer', 'slider', ['numeric']),
          _combo('integer', 'stepper', ['numeric']),
          _combo('integer', 'textField', []),
          _combo('integer', 'textArea', []),
          // Float
          _combo('float', 'slider', ['numeric']),
          _combo('float', 'stepper', ['numeric']),
          _combo('float', 'textField', []),
          _combo('float', 'textArea', []),
          // Text
          _combo('text', 'textField', []),
          _combo('text', 'textArea', []),
          // Boolean
          _combo('boolean', 'toggleSwitch', []),
          _combo('boolean', 'checkbox', []),
          // DateTime
          _combo('datetime', 'datePicker', []),
          _combo('datetime', 'timePicker', []),
          _combo('datetime', 'textField', []),
          _combo('datetime', 'textArea', []),
          // Enumerated
          _combo('enumerated', 'dropdown', ['enumerated']),
          _combo('enumerated', 'radio', ['enumerated']),
          _combo('enumerated', 'chips', ['enumerated']),
          // Dimension
          _combo('dimension', 'slider', ['numeric']),
          _combo('dimension', 'stepper', ['numeric']),
          _combo('dimension', 'textField', []),
          _combo('dimension', 'textArea', []),
          // Reference
          _combo('reference', 'dropdown', ['enumerated']),
          _combo('reference', 'radio', ['enumerated']),
          _combo('reference', 'chips', ['enumerated']),
          _combo('reference', 'textField', []),
          _combo('reference', 'textArea', []),
        ],
      },
      'colorPalette': {
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
            'minItems': 2,
            'maxItems': 4,
          },
          'neutrals': {
            'type': 'array',
            'items': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
            'minItems': 2,
            'maxItems': 3,
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
          },
          'subtitleWeight': {
            'type': 'integer',
            'minimum': 100,
            'maximum': 900,
            'multipleOf': 100,
          },
          'bodyWeight': {
            'type': 'integer',
            'minimum': 100,
            'maximum': 900,
            'multipleOf': 100,
          },
        },
        'additionalProperties': false,
      },
    },
    'additionalProperties': false,
  };
}

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

Future<Map<String, dynamic>?> _testWithGemini(String apiKey, Map<String, dynamic> schema) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': 'Generate a valid example matching this schema. Pick any valid field combination.'}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': schema,
    },
  };
  
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return jsonDecode(text) as Map<String, dynamic>;
    } else {
      print('❌ API Error ${response.statusCode}:');
      print(response.body);
      return null;
    }
  } catch (e) {
    print('❌ Request failed: $e');
    return null;
  }
}

void _validateResponse(Map<String, dynamic> response) {
  // Check fieldCombination
  if (response.containsKey('fieldCombination')) {
    final fc = response['fieldCombination'] as Map<String, dynamic>;
    print('   ✅ fieldCombination present');
    print('      - fieldType: ${fc['fieldType']}');
    print('      - uiElement: ${fc['uiElement']}');
    print('      - requiredValidators: ${fc['requiredValidators']}');
  } else {
    print('   ⚠️ fieldCombination missing');
  }
  
  // Check colorPalette
  if (response.containsKey('colorPalette')) {
    final cp = response['colorPalette'] as Map<String, dynamic>;
    print('   ✅ colorPalette present');
    print('      - colors: ${(cp['colors'] as List?)?.length ?? 0} items');
    print('      - neutrals: ${(cp['neutrals'] as List?)?.length ?? 0} items');
  } else {
    print('   ⚠️ colorPalette missing');
  }
  
  // Check fontConfiguration
  if (response.containsKey('fontConfiguration')) {
    final fc = response['fontConfiguration'] as Map<String, dynamic>;
    print('   ✅ fontConfiguration present');
    print('      - titleWeight: ${fc['titleWeight']}');
    print('      - subtitleWeight: ${fc['subtitleWeight']}');
    print('      - bodyWeight: ${fc['bodyWeight']}');
  } else {
    print('   ⚠️ fontConfiguration missing');
  }
}

Map<String, int> _analyzeSchema(Map<String, dynamic> schema) {
  int propertyCount = 0;
  int enumCount = 0;
  int oneOfCount = 0;
  int maxDepth = 0;
  
  void analyze(Map<String, dynamic> obj, int depth) {
    maxDepth = depth > maxDepth ? depth : maxDepth;
    
    for (final entry in obj.entries) {
      final value = entry.value;
      if (entry.key == 'properties' && value is Map<String, dynamic>) {
        propertyCount += value.length;
        for (final prop in value.values) {
          if (prop is Map<String, dynamic>) analyze(prop, depth + 1);
        }
      } else if (entry.key == 'enum' && value is List) {
        enumCount += value.length;
      } else if (entry.key == 'oneOf' && value is List) {
        oneOfCount += value.length;
        for (final item in value) {
          if (item is Map<String, dynamic>) analyze(item, depth + 1);
        }
      } else if (value is Map<String, dynamic>) {
        analyze(value, depth + 1);
      }
    }
  }
  
  analyze(schema, 0);
  return {'properties': propertyCount, 'enums': enumCount, 'oneOfs': oneOfCount, 'depth': maxDepth};
}
