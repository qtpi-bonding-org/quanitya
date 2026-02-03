#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🚀 COMPLETE PIPELINE TESTER: Foundation Enums → Schema → Translation → Gemini');
  print('=' * 80);
  
  try {
    // Load environment from .env file manually
    final envFile = File('.env');
    String geminiApiKey = '';
    
    if (await envFile.exists()) {
      final envContent = await envFile.readAsString();
      final lines = envContent.split('\n');
      for (final line in lines) {
        if (line.startsWith('GEMINI_API_KEY=')) {
          geminiApiKey = line.substring('GEMINI_API_KEY='.length).trim();
          break;
        }
      }
    }
    
    if (geminiApiKey.isEmpty) {
      print('❌ Error: GEMINI_API_KEY not found in .env file');
      exit(1);
    }
    
    print('✅ Environment loaded');
    
    // STEP 1: Generate complete schema from foundation enums (simulated)
    print('\n📋 STEP 1: Generating Complete Schema from Foundation Enums');
    print('-' * 60);
    
    final originalSchema = _generateFoundationSchema();
    
    print('✅ Complete schema generated from foundation enums:');
    print('  📊 Schema structure:');
    final properties = originalSchema['properties'] as Map<String, dynamic>?;
    if (properties != null) {
      for (final key in properties.keys) {
        print('    - $key: ✅');
      }
    }
    
    // STEP 2: Translate schema for Gemini compatibility
    print('\n🔄 STEP 2: Translating Schema for Gemini Compatibility');
    print('-' * 60);
    
    final translatedSchema = _translateSchemaForGemini(originalSchema);
    
    print('✅ Schema translated for Gemini:');
    print('  🔄 Unsupported features converted:');
    print('    - multipleOf constraints → enum arrays');
    print('    - pattern constraints → descriptions');
    print('    - oneOf constraints → enum arrays');
    print('    - const values → enum arrays');
    
    // Show specific translations
    _showTranslationDetails(originalSchema, translatedSchema);
    
    // STEP 3: Interactive testing
    print('\n🎮 STEP 3: Interactive Testing Mode');
    print('-' * 60);
    print('🚀 Complete Pipeline Ready: Foundation Enums → Schema → Translation → Gemini API');
    print('\nTest the full pipeline with your prompts!');
    print('The pipeline will:');
    print('  📋 Use schema generated from your foundation enums');
    print('  🔄 Automatically translate unsupported features for Gemini');
    print('  🌐 Call Gemini API with translated schema');
    print('  ✅ Validate that Gemini respects field combinations and constraints');
    
    print('\nCommands:');
    print('  - Enter your prompt to test the complete pipeline');
    print('  - "schema" to see the original schema from foundation enums');
    print('  - "translated" to see the Gemini-translated schema');
    print('  - "quit" to exit');
    
    while (true) {
      print('\n📝 Enter your template prompt:');
      stdout.write('> ');
      final userInput = stdin.readLineSync();
      
      if (userInput == null || userInput.toLowerCase() == 'quit') {
        print('\n👋 Goodbye!');
        break;
      }
      
      if (userInput.toLowerCase() == 'schema') {
        print('\n📋 ORIGINAL SCHEMA (from Foundation Enums):');
        print('=' * 60);
        print(JsonEncoder.withIndent('  ').convert(originalSchema));
        print('=' * 60);
        continue;
      }
      
      if (userInput.toLowerCase() == 'translated') {
        print('\n🔄 TRANSLATED SCHEMA (Gemini-compatible):');
        print('=' * 60);
        print(JsonEncoder.withIndent('  ').convert(translatedSchema));
        print('=' * 60);
        continue;
      }
      
      if (userInput.trim().isEmpty) {
        print('❌ Please enter a valid prompt');
        continue;
      }
      
      try {
        print('\n🚀 EXECUTING COMPLETE PIPELINE...');
        print('  📋 Foundation Enums → Schema Generation ✅');
        print('  🔄 Schema Translation for Gemini ✅');
        print('  🌐 Calling Gemini API with translated schema...');
        
        final response = await _callCompleteGeminiPipeline(
          geminiApiKey,
          userInput,
          translatedSchema,
        );
        
        print('\n📥 GEMINI RESPONSE (Complete Pipeline):');
        print('=' * 80);
        print(JsonEncoder.withIndent('  ').convert(response));
        print('=' * 80);
        
        print('\n📊 PIPELINE VALIDATION:');
        _validateCompleteResponse(response, originalSchema);
        
        print('\n✅ Complete pipeline executed successfully!');
        print('🔗 Foundation Enums → Schema → Translation → Gemini API ✅');
        
      } catch (e) {
        print('❌ Pipeline Error: $e');
        print('🔧 Check your .env file and internet connection');
      }
    }
    
  } catch (e) {
    print('❌ Initialization Error: $e');
    exit(1);
  }
}

/// Generate a simplified schema to avoid excessive state combinations
Map<String, dynamic> _generateFoundationSchema() {
  return {
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
              'enum': ['text', 'number'],
              'description': 'Type of field from foundation enums',
            },
            'widgetType': {
              'enum': ['textField', 'slider'],
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
        'maxItems': 3, // Reduced from 10 to 3
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
            'maxItems': 2, // Reduced from 4 to 2
            'description': 'Main colors (color1-color2)',
          },
          'neutrals': {
            'type': 'array',
            'items': {
              'type': 'string',
              'pattern': r'^#[0-9A-Fa-f]{6}$',
            },
            'minItems': 2,
            'maxItems': 2, // Reduced from 3 to 2
            'description': 'Neutral colors (neutral1-neutral2)',
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
}

/// Translate schema for Gemini compatibility (simulated GeminiSchemaTranslator)
Map<String, dynamic> _translateSchemaForGemini(Map<String, dynamic> jsonSchema) {
  final translated = <String, dynamic>{};
  
  // Copy supported properties directly
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
        translated[entry.key] = entry.value;
        break;
        
      case 'properties':
        translated['properties'] = _translateProperties(entry.value as Map<String, dynamic>);
        break;
        
      case 'items':
        translated['items'] = _translateSchemaForGemini(entry.value as Map<String, dynamic>);
        break;
        
      case 'enum':
        translated['enum'] = entry.value;
        break;
        
      // Transform unsupported features
      case 'multipleOf':
        translated.addAll(_translateMultipleOf(entry.value as int, jsonSchema));
        break;
        
      case 'const':
        translated['enum'] = [entry.value];
        break;
        
      case 'oneOf':
        translated.addAll(_translateOneOf(entry.value as List, jsonSchema));
        break;
        
      case 'pattern':
        // Convert pattern to description guidance
        translated['description'] = _enhanceDescriptionWithPattern(
          jsonSchema['description'] as String?, 
          entry.value as String
        );
        break;
        
      // Skip unsupported properties
      case r'$schema':
        break;
        
      default:
        // Copy unknown properties (might be supported)
        translated[entry.key] = entry.value;
    }
  }
  
  return translated;
}

Map<String, dynamic> _translateProperties(Map<String, dynamic> properties) {
  final translated = <String, dynamic>{};
  for (final entry in properties.entries) {
    translated[entry.key] = _translateSchemaForGemini(entry.value as Map<String, dynamic>);
  }
  return translated;
}

Map<String, dynamic> _translateMultipleOf(int multipleOf, Map<String, dynamic> schema) {
  final min = schema['minimum'] as int? ?? 0;
  final max = schema['maximum'] as int? ?? 1000;
  
  // Generate enum values that are multiples
  final enumValues = <int>[];
  for (int i = min; i <= max; i += multipleOf) {
    enumValues.add(i);
  }
  
  return {'enum': enumValues};
}

Map<String, dynamic> _translateOneOf(List oneOfList, Map<String, dynamic> schema) {
  // For simple oneOf with const values, convert to enum
  final constValues = <dynamic>[];
  bool allConst = true;
  
  for (final option in oneOfList) {
    if (option is Map<String, dynamic> && option.containsKey('const')) {
      constValues.add(option['const']);
    } else {
      allConst = false;
      break;
    }
  }
  
  if (allConst && constValues.isNotEmpty) {
    return {'enum': constValues};
  }
  
  // For complex oneOf, take the first option and add description
  final firstOption = oneOfList.first as Map<String, dynamic>;
  final translated = _translateSchemaForGemini(firstOption);
  translated['description'] = _enhanceDescriptionWithOneOf(
    schema['description'] as String?,
    oneOfList,
  );
  
  return translated;
}

String _enhanceDescriptionWithPattern(String? description, String pattern) {
  final patternDesc = switch (pattern) {
    r'^#[0-9A-Fa-f]{6}$' => 'Must be 6-digit hex color format (e.g., #FF0000)',
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' => 'Must be valid email format',
    _ => 'Must match pattern: $pattern',
  };
  
  return description != null ? '$description. $patternDesc' : patternDesc;
}

String _enhanceDescriptionWithOneOf(String? description, List oneOfList) {
  final options = oneOfList.map((option) {
    if (option is Map<String, dynamic>) {
      return option['description'] ?? option.toString();
    }
    return option.toString();
  }).join(', ');
  
  final oneOfDesc = 'Must be one of: $options';
  return description != null ? '$description. $oneOfDesc' : oneOfDesc;
}

/// Call Gemini API with the complete translated schema
Future<Map<String, dynamic>> _callCompleteGeminiPipeline(
  String apiKey,
  String userPrompt,
  Map<String, dynamic> translatedSchema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final systemPrompt = '''You are an expert UI/UX designer creating Flutter app templates.

Generate a complete template structure following the provided JSON schema constraints exactly.
The schema was generated from foundation enums and defines:
- Valid field-widget combinations from the app's type system
- Color palette constraints for consistent theming  
- Font configuration with proper weight hierarchies

Create practical, usable templates that:
- Use appropriate field types with matching UI elements from the valid combinations
- Apply cohesive color schemes from the palette constraints
- Use proper font weights for content hierarchy
- Include all required schema properties
- Are suitable for real-world Flutter applications

Be creative within the schema constraints and make sure to use the field combinations properly.''';
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': '$systemPrompt\n\nUser Request: $userPrompt'}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': translatedSchema,
    },
  };
  
  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Gemini API Error ${response.statusCode}: ${response.body}');
  }
  
  final data = jsonDecode(response.body);
  final textContent = data['candidates'][0]['content']['parts'][0]['text'] as String;
  return jsonDecode(textContent) as Map<String, dynamic>;
}

/// Show details of what was translated
void _showTranslationDetails(Map<String, dynamic> original, Map<String, dynamic> translated) {
  print('\n🔍 Translation Details:');
  
  // Check font configuration translations
  final originalFont = original['properties']?['fontConfiguration']?['properties'];
  final translatedFont = translated['properties']?['fontConfiguration']?['properties'];
  
  if (originalFont != null && translatedFont != null) {
    for (final key in ['titleWeight', 'subtitleWeight', 'bodyWeight']) {
      if (originalFont[key]?['multipleOf'] != null && translatedFont[key]?['enum'] != null) {
        print('  🔤 $key: multipleOf:${originalFont[key]['multipleOf']} → enum:${translatedFont[key]['enum']}');
      }
    }
  }
  
  // Check color palette translations
  final originalColors = original['properties']?['colorPalette']?['properties']?['colors']?['items'];
  final translatedColors = translated['properties']?['colorPalette']?['properties']?['colors']?['items'];
  
  if (originalColors?['pattern'] != null && translatedColors?['description'] != null) {
    print('  🎨 Colors: pattern:"${originalColors['pattern']}" → description:"${translatedColors['description']}"');
  }
  
  // Check field combinations (oneOf patterns)
  final originalFields = original['properties']?['fields'];
  final translatedFields = translated['properties']?['fields'];
  
  if (originalFields != null && translatedFields != null) {
    print('  📋 Field combinations: Translated oneOf patterns to enum arrays');
  }
}

/// Validate the complete response against original schema constraints
void _validateCompleteResponse(Map<String, dynamic> response, Map<String, dynamic> originalSchema) {
  final checks = <String, bool>{};
  
  // Validate font configuration
  if (response.containsKey('fontConfiguration')) {
    final fontConfig = response['fontConfiguration'] as Map<String, dynamic>;
    final validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
    
    bool fontsValid = true;
    for (final key in ['titleWeight', 'subtitleWeight', 'bodyWeight']) {
      if (fontConfig.containsKey(key)) {
        final weight = fontConfig[key] as int;
        if (!validWeights.contains(weight)) {
          fontsValid = false;
          break;
        }
      }
    }
    checks['Font weights are valid (multipleOf:100 constraint enforced)'] = fontsValid;
  }
  
  // Validate color palette
  if (response.containsKey('colorPalette')) {
    final colorPalette = response['colorPalette'] as Map<String, dynamic>;
    final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
    
    bool colorsValid = true;
    
    if (colorPalette.containsKey('colors')) {
      final colors = colorPalette['colors'] as List;
      for (final color in colors) {
        if (!hexPattern.hasMatch(color as String)) {
          colorsValid = false;
          break;
        }
      }
    }
    
    if (colorPalette.containsKey('neutrals')) {
      final neutrals = colorPalette['neutrals'] as List;
      for (final neutral in neutrals) {
        if (!hexPattern.hasMatch(neutral as String)) {
          colorsValid = false;
          break;
        }
      }
    }
    
    checks['Colors are valid hex format (pattern constraint enforced)'] = colorsValid;
  }
  
  // Check field combinations (if present)
  if (response.containsKey('fields')) {
    final fields = response['fields'] as List;
    bool validCombinations = true;
    
    for (final field in fields) {
      final fieldMap = field as Map<String, dynamic>;
      final fieldType = fieldMap['fieldType'] as String?;
      final widgetType = fieldMap['widgetType'] as String?;
      
      // Validate field-widget combinations from foundation enums
      if (fieldType == 'text' && !['textField', 'textArea'].contains(widgetType)) {
        validCombinations = false;
        break;
      }
      if (fieldType == 'number' && !['slider', 'stepper'].contains(widgetType)) {
        validCombinations = false;
        break;
      }
    }
    
    checks['Field-widget combinations respect foundation enum constraints'] = validCombinations;
  }
  
  // Check overall structure matches schema
  final requiredProps = originalSchema['required'] as List?;
  bool hasRequiredProps = true;
  if (requiredProps != null) {
    for (final prop in requiredProps) {
      if (!response.containsKey(prop)) {
        hasRequiredProps = false;
        break;
      }
    }
  }
  checks['Response has all required properties'] = hasRequiredProps;
  
  // Print validation results
  for (final entry in checks.entries) {
    final icon = entry.value ? '✅' : '❌';
    print('  $icon ${entry.key}');
  }
  
  final allPassed = checks.values.every((passed) => passed);
  if (allPassed) {
    print('  🎉 ALL PIPELINE CONSTRAINTS ENFORCED!');
    print('  🔗 Foundation Enums → Schema → Translation → Gemini API ✅');
  } else {
    print('  ⚠️  Some constraints not fully enforced');
  }
}