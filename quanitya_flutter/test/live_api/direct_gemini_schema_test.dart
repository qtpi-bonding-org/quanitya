import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';

import 'live_api_test_helper.dart';

/// Direct Gemini API Schema Validation Tests.
/// Skipped automatically if GEMINI_API_KEY is not found in .env
@Tags(['live_api'])
void main() {
  group('Direct Gemini API Schema Validation Tests', () {
    GetIt? testGetIt;
    AiTemplateGenerator? aiGenerator;
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
      
      // Set up dependency injection (simplified script)
      testGetIt = GetIt.asNewInstance();
      
      // Register core services
      testGetIt!.registerLazySingleton<SymbolicCombinationGenerator>(
        () => SymbolicCombinationGenerator(),
      );
      
      testGetIt!.registerFactory<UnifiedSchemaGenerator>(
        () => UnifiedSchemaGenerator(),
      );
      
      testGetIt!.registerFactory<AiTemplateGenerator>(
        () => AiTemplateGenerator(
          testGetIt!<SymbolicCombinationGenerator>(),
          testGetIt!<UnifiedSchemaGenerator>(),
        ),
      );
      
      // Get services
      aiGenerator = testGetIt!<AiTemplateGenerator>();
    });

    tearDownAll(() {
      testGetIt?.reset();
    });

    test('Direct Gemini API - Color constraint enforcement', () async {
      if (shouldSkip || geminiApiKey == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      // Create a focused color schema
      final colorSchema = {
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {
              'type': 'string',
              'pattern': r'^#[0-9A-Fa-f]{6}$',
            },
            'minItems': 3,
            'maxItems': 3,
            'description': 'Exactly 3 hex colors in #FFFFFF format',
          },
        },
        'required': ['colors'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate 3 beautiful colors for a modern app: primary, secondary, accent.',
        colorSchema,
      );
      
      // Validate response structure
      expect(response, isA<Map<String, dynamic>>());
      expect(response.containsKey('colors'), isTrue);
      
      final colors = response['colors'] as List;
      expect(colors.length, equals(3));
      
      // Validate each color matches the pattern EXACTLY
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (int i = 0; i < colors.length; i++) {
        final color = colors[i] as String;
        
        expect(color, isA<String>());
        expect(hexPattern.hasMatch(color), isTrue, 
          reason: 'Color "$color" should match pattern ^#[0-9A-Fa-f]{6}\$');
        expect(color.length, equals(7), 
          reason: 'Color "$color" should be exactly 7 characters (#FFFFFF)');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Direct Gemini API - Font weight constraint enforcement', () async {
      if (shouldSkip || geminiApiKey == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      final fontSchema = {
        'type': 'object',
        'properties': {
          'fontWeights': {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100,
              },
              'body': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100,
              },
              'caption': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100,
              },
            },
            'required': ['title', 'body', 'caption'],
            'additionalProperties': false,
          },
        },
        'required': ['fontWeights'],
        'additionalProperties': false,
      };
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate appropriate font weights for title (bold), body (normal), and caption (light) text.',
        fontSchema,
      );
      
      final fontWeights = response['fontWeights'] as Map<String, dynamic>;
      
      for (final entry in fontWeights.entries) {
        final weight = entry.value as int;
        
        // Validate constraints are ENFORCED
        expect(weight, isA<int>());
        expect(weight >= 100, isTrue, reason: 'Weight $weight should be >= 100');
        expect(weight <= 900, isTrue, reason: 'Weight $weight should be <= 900');
        expect(weight % 100, equals(0), reason: 'Weight $weight should be multiple of 100');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Direct Gemini API - Complete schema validation', () async {
      if (shouldSkip || geminiApiKey == null || aiGenerator == null) {
        markTestSkipped(LiveApiTestHelper.skipGeminiMessage);
        return;
      }
      
      // Generate the full schema from your system
      final schema = aiGenerator!.generateSchema();
      
      final response = await _callGeminiWithSchema(
        geminiApiKey!,
        'Generate a complete template configuration for a user registration form with name, email, age, and preferences. Include colors, fonts, and field configurations.',
        schema,
      );
      
      // Validate top-level structure
      expect(response.containsKey('colorPalette'), isTrue);
      expect(response.containsKey('fontConfiguration'), isTrue);
      
      // Validate color palette constraints
      if (response.containsKey('colorPalette')) {
        final colorPalette = response['colorPalette'] as Map<String, dynamic>;
        
        if (colorPalette.containsKey('colors')) {
          final colors = colorPalette['colors'] as List;
          
          final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
          for (final color in colors) {
            expect(hexPattern.hasMatch(color as String), isTrue,
              reason: 'Color $color must match #FFFFFF pattern');
          }
        }
        
        if (colorPalette.containsKey('neutrals')) {
          final neutrals = colorPalette['neutrals'] as List;
          
          final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
          for (final color in neutrals) {
            expect(hexPattern.hasMatch(color as String), isTrue,
              reason: 'Neutral color $color must match #FFFFFF pattern');
          }
        }
      }
      
      // Validate font configuration constraints
      if (response.containsKey('fontConfiguration')) {
        final fontConfig = response['fontConfiguration'] as Map<String, dynamic>;
        
        for (final entry in fontConfig.entries) {
          if (entry.key.contains('Weight') && entry.value != null) {
            final weight = entry.value as int;
            expect(weight % 100, equals(0),
              reason: 'Font weight $weight must be multiple of 100');
            expect(weight >= 100 && weight <= 900, isTrue,
              reason: 'Font weight $weight must be between 100-900');
          }
        }
      }
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}

/// Call Gemini API directly with structured output
Future<Map<String, dynamic>> _callGeminiWithSchema(
  String apiKey,
  String prompt,
  Map<String, dynamic> schema,
) async {
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey';
  
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
      'responseSchema': schema,
    },
  };
  
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(requestBody),
  );
  
  if (response.statusCode != 200) {
    final errorBody = response.body;
    throw Exception('Gemini API Error ${response.statusCode}: $errorBody');
  }
  
  final data = jsonDecode(response.body);
  
  if (data['candidates'] == null || data['candidates'].isEmpty) {
    throw Exception('No candidates in Gemini response: ${response.body}');
  }
  
  final candidate = data['candidates'][0];
  if (candidate['content'] == null || candidate['content']['parts'] == null) {
    throw Exception('No content in Gemini candidate: ${response.body}');
  }
  
  final textContent = candidate['content']['parts'][0]['text'] as String;
  return jsonDecode(textContent) as Map<String, dynamic>;
}
