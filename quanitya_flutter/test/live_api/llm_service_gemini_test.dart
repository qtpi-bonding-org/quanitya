import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quanitya_flutter/infrastructure/llm/services/schema_translator.dart';

import 'live_api_test_helper.dart';

/// Tests for Schema Translator with Real Production Schema.
/// Skipped automatically if GEMINI_API_KEY is not found in .env
@Tags(['live_api'])
void main() {
  group('Schema Translator with Real Production Schema', () {
    String? geminiApiKey;
    bool shouldSkip = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      if (!LiveApiTestHelper.hasGeminiKey) {
        shouldSkip = true;
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      geminiApiKey = LiveApiTestHelper.geminiApiKey;
      print('✅ Gemini API Key loaded');
    });

    test('Real Production Schema - Font weights with multipleOf constraint', () async {
      if (shouldSkip || geminiApiKey == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      print('\n🔄 Testing real production schema with Gemini translation...');
      
      // This is the ACTUAL schema from SchemaReorganizer.generateFontConfigurationSchema()
      final realProductionSchema = {
        'type': 'object',
        'properties': {
          'fontConfiguration': {
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
                'multipleOf': 100, // ← This is unsupported by Gemini!
                'default': 600,
                'description': 'Font weight for titles',
              },
              'subtitleWeight': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100, // ← This is unsupported by Gemini!
                'default': 400,
                'description': 'Font weight for subtitles',
              },
              'bodyWeight': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100, // ← This is unsupported by Gemini!
                'default': 400,
                'description': 'Font weight for body text',
              },
            },
            'additionalProperties': false,
          },
          'colorPalette': {
            'type': 'object',
            'properties': {
              'colors': {
                'type': 'array',
                'items': {
                  'type': 'string',
                  'pattern': r'^#[0-9A-Fa-f]{6}$', // ← This is unsupported by Gemini!
                },
                'minItems': 2,
                'maxItems': 4,
                'description': 'Main colors (color1-color4)',
              },
              'neutrals': {
                'type': 'array',
                'items': {
                  'type': 'string',
                  'pattern': r'^#[0-9A-Fa-f]{6}$', // ← This is unsupported by Gemini!
                },
                'minItems': 2,
                'maxItems': 3,
                'description': 'Neutral colors (neutral1-neutral3)',
              },
            },
            'required': ['colors', 'neutrals'],
            'additionalProperties': false,
          },
        },
        'required': ['fontConfiguration', 'colorPalette'],
        'additionalProperties': false,
      };
      
      print('📋 Original production schema has unsupported Gemini features:');
      print('  - multipleOf: 100 (for font weights)');
      print('  - pattern: ^#[0-9A-Fa-f]{6}\$ (for hex colors)');
      
      // Translate schema using our translator
      final translator = GeminiSchemaTranslator();
      final translatedSchema = translator.translateSchema(realProductionSchema);
      
      print('📋 Translated schema for Gemini compatibility:');
      
      // Check font weight translations
      final titleWeight = translatedSchema['properties']['fontConfiguration']['properties']['titleWeight'];
      final subtitleWeight = translatedSchema['properties']['fontConfiguration']['properties']['subtitleWeight'];
      final bodyWeight = translatedSchema['properties']['fontConfiguration']['properties']['bodyWeight'];
      
      print('  - titleWeight.enum: ${titleWeight['enum']}');
      print('  - subtitleWeight.enum: ${subtitleWeight['enum']}');
      print('  - bodyWeight.enum: ${bodyWeight['enum']}');
      
      // Verify multipleOf → enum conversion
      final expectedWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
      expect(titleWeight['enum'], equals(expectedWeights));
      expect(subtitleWeight['enum'], equals(expectedWeights));
      expect(bodyWeight['enum'], equals(expectedWeights));
      
      // Check pattern → description conversion
      final colorItems = translatedSchema['properties']['colorPalette']['properties']['colors']['items'];
      final neutralItems = translatedSchema['properties']['colorPalette']['properties']['neutrals']['items'];
      
      expect(colorItems['description'], contains('6-digit hex color'));
      expect(neutralItems['description'], contains('6-digit hex color'));
      print('  - pattern constraints converted to descriptions');
      
      // Test with real Gemini API
      final response = await _callGeminiAPI(
        geminiApiKey!,
        'Generate a font configuration with appropriate weights (bold for titles, normal for body) and a color palette with 3 main colors and 2 neutral colors. Use proper hex color format like #FF0000.',
        translatedSchema,
      );
      
      print('📥 Gemini API Response with translated schema:');
      print(JsonEncoder.withIndent('  ').convert(response));
      
      // Validate font weights are from allowed enum
      final fontConfig = response['fontConfiguration'] as Map<String, dynamic>;
      final titleWeightResult = fontConfig['titleWeight'] as int;
      final subtitleWeightResult = fontConfig['subtitleWeight'] as int;
      final bodyWeightResult = fontConfig['bodyWeight'] as int;
      
      expect(expectedWeights.contains(titleWeightResult), isTrue);
      expect(expectedWeights.contains(subtitleWeightResult), isTrue);
      expect(expectedWeights.contains(bodyWeightResult), isTrue);
      
      // Validate color format (should be hex even without pattern constraint)
      final colorPalette = response['colorPalette'] as Map<String, dynamic>;
      final colors = colorPalette['colors'] as List;
      final neutrals = colorPalette['neutrals'] as List;
      
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (final color in colors) {
        expect(hexPattern.hasMatch(color as String), isTrue, 
          reason: 'Color $color should be valid hex format');
      }
      for (final neutral in neutrals) {
        expect(hexPattern.hasMatch(neutral as String), isTrue,
          reason: 'Neutral $neutral should be valid hex format');
      }
      
      print('✅ Real production schema translation + API call SUCCESSFUL!');
      print('🎯 All constraints properly enforced by Gemini');
      
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Provider Detection - Correct translator selection', () async {
      print('\n🔍 Testing provider detection...');
      
      final testCases = [
        ('google/gemini-pro', GeminiSchemaTranslator),
        ('gemini-2.0-flash', GeminiSchemaTranslator),
        ('openai/gpt-4', OpenAISchemaTranslator),
        ('gpt-4o-mini', OpenAISchemaTranslator),
        ('anthropic/claude-3', AnthropicSchemaTranslator),
        ('claude-3-sonnet', AnthropicSchemaTranslator),
        ('unknown-model', OpenAISchemaTranslator), // Default
      ];
      
      for (final (model, expectedType) in testCases) {
        final translator = SchemaTranslatorFactory.getTranslatorForModel(model);
        expect(translator.runtimeType, equals(expectedType));
        print('✅ $model → ${translator.runtimeType}');
      }
      
      print('🎯 All provider detection working correctly');
    });
  });
}

/// Call Gemini API with translated schema
Future<Map<String, dynamic>> _callGeminiAPI(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': prompt}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': schema,
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