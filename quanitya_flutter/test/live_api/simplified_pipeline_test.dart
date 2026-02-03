import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/llm/services/schema_translator.dart';

import 'live_api_test_helper.dart';

void main() {
  group('Simplified Pipeline: Schema Translation → Gemini API', () {
    String? geminiApiKey;
    bool hasApiKey = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      hasApiKey = LiveApiTestHelper.hasGeminiKey;
      
      if (!hasApiKey) return;
      
      geminiApiKey = LiveApiTestHelper.geminiApiKey;
    });

    test('Core Pipeline with Real Schema Features', () async {
      // STEP 1: Create a realistic schema with unsupported Gemini features
      final originalSchema = {
        'type': 'object',
        'properties': {
          'templateName': {'type': 'string', 'description': 'Name of the template'},
          'fontConfiguration': {
            'type': 'object',
            'properties': {
              'titleWeight': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100, // ← Unsupported by Gemini
                'description': 'Font weight for titles',
              },
              'bodyWeight': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100, // ← Unsupported by Gemini
                'description': 'Font weight for body text',
              },
            },
            'required': ['titleWeight', 'bodyWeight'],
            'additionalProperties': false,
          },
          'colorPalette': {
            'type': 'object',
            'properties': {
              'primaryColor': {
                'type': 'string',
                'pattern': r'^#[0-9A-Fa-f]{6}$', // ← Unsupported by Gemini
                'description': 'Primary color in hex format',
              },
              'secondaryColor': {
                'type': 'string',
                'pattern': r'^#[0-9A-Fa-f]{6}$', // ← Unsupported by Gemini
                'description': 'Secondary color in hex format',
              },
            },
            'required': ['primaryColor', 'secondaryColor'],
            'additionalProperties': false,
          },
          'templateType': {
            'oneOf': [ // ← Unsupported by Gemini
              {'const': 'fitness'},
              {'const': 'recipe'},
              {'const': 'project'},
              {'const': 'journal'},
            ],
          },
        },
        'required': ['templateName', 'fontConfiguration', 'colorPalette', 'templateType'],
        'additionalProperties': false,
      };
      
      // STEP 2: Translate Schema
      final translator = GeminiSchemaTranslator();
      final translatedSchema = translator.translateSchema(originalSchema);
      
      expect(translatedSchema, isNotNull);
      expect(translatedSchema['properties'], isA<Map<String, dynamic>>());
      
      // Verify translations
      final titleWeight = translatedSchema['properties']['fontConfiguration']['properties']['titleWeight'];
      expect(titleWeight['enum'], isA<List>());
      
      final primaryColor = translatedSchema['properties']['colorPalette']['properties']['primaryColor'];
      expect(primaryColor['description'], isA<String>());
      
      final templateType = translatedSchema['properties']['templateType'];
      expect(templateType['enum'], isA<List>());
      
      // STEP 3: Test with a single prompt
      final testPrompt = 'Create a fitness tracking template with bold titles and blue colors';
      
      final response = await _callGeminiWithTranslatedSchema(
        geminiApiKey!,
        testPrompt,
        translatedSchema,
      );
      
      expect(response, isA<Map<String, dynamic>>());
      expect(response['templateName'], isA<String>());
      
      // Validate constraints
      _validateResponse(response);
    }, timeout: const Timeout(Duration(minutes: 2)), skip: !hasApiKey ? 'GEMINI_API_KEY not found in .env' : null);
  });
}

Future<Map<String, dynamic>> _callGeminiWithTranslatedSchema(
  String apiKey,
  String userPrompt,
  Map<String, dynamic> translatedSchema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final systemPrompt = '''You are a UI designer creating Flutter app templates.

Generate a template configuration following the schema exactly. The schema has been translated for Gemini compatibility:
- Font weights are provided as enum values (multiples of 100)
- Colors should be hex format (#FFFFFF)
- Template types are from the allowed enum values

Create practical, usable templates that match the user's request while staying within the schema constraints.''';
  
  final requestBody = {
    'contents': [{'parts': [{'text': '$systemPrompt\n\nUser Request: $userPrompt'}]}],
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

void _validateResponse(Map<String, dynamic> response) {
  final checks = <String, bool>{};
  
  // Validate font weights (should be multiples of 100)
  final fontConfig = response['fontConfiguration'] as Map<String, dynamic>;
  final titleWeight = fontConfig['titleWeight'] as int;
  final bodyWeight = fontConfig['bodyWeight'] as int;
  final validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
  
  checks['Font weights are valid (multipleOf constraint)'] = 
      validWeights.contains(titleWeight) && validWeights.contains(bodyWeight);
  
  // Validate colors (should be hex format)
  final colorPalette = response['colorPalette'] as Map<String, dynamic>;
  final primaryColor = colorPalette['primaryColor'] as String;
  final secondaryColor = colorPalette['secondaryColor'] as String;
  final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
  
  checks['Colors are valid hex format (pattern constraint)'] = 
      hexPattern.hasMatch(primaryColor) && hexPattern.hasMatch(secondaryColor);
  
  // Validate template type (should be from enum)
  final templateType = response['templateType'] as String;
  final validTypes = ['fitness', 'recipe', 'project', 'journal'];
  
  checks['Template type is valid (oneOf constraint)'] = validTypes.contains(templateType);
  
  // Verify all checks passed
  final allPassed = checks.values.every((passed) => passed);
  expect(allPassed, isTrue, reason: 'All schema constraints should be enforced');
}