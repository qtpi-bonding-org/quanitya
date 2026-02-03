import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/infrastructure/llm/services/llm_service.dart';
import 'package:quanitya_flutter/infrastructure/llm/models/llm_types.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import 'live_api_test_helper.dart';

void main() {
  group('LLM Schema Validation Tests', () {
    late GetIt testGetIt;
    late AiTemplateGenerator aiGenerator;
    late LlmService llmService;
    late LlmConfig llmConfig;
    bool hasApiKey = false;

    setUpAll(() async {
      await LiveApiTestHelper.loadEnv();
      hasApiKey = LiveApiTestHelper.hasOpenRouterKey;
      
      if (!hasApiKey) return;
      
      final apiKey = LiveApiTestHelper.openRouterApiKey!;
      
      testGetIt = GetIt.asNewInstance();
      testGetIt.registerLazySingleton<http.Client>(() => http.Client());
      testGetIt.registerLazySingleton<SymbolicCombinationGenerator>(() => SymbolicCombinationGenerator());
      testGetIt.registerFactory<UnifiedSchemaGenerator>(() => UnifiedSchemaGenerator());
      testGetIt.registerFactory<AiTemplateGenerator>(
        () => AiTemplateGenerator(
          testGetIt<SymbolicCombinationGenerator>(),
          testGetIt<UnifiedSchemaGenerator>(),
        ),
      );
      testGetIt.registerLazySingleton<Client>(() => Client('http://localhost:8080/'));
      testGetIt.registerLazySingleton<LlmService>(() => LlmService(testGetIt<http.Client>(), testGetIt<Client>()));
      
      aiGenerator = testGetIt<AiTemplateGenerator>();
      llmService = testGetIt<LlmService>();
      
      llmConfig = LlmConfig.openRouter(
        apiKey: apiKey,
        model: 'openai/gpt-4o-mini',
        appName: 'Quanitya Schema Validator',
        appUrl: 'https://github.com/qtpi-bonding/quanitya_flutter',
      );
    });

    tearDownAll(() {
      if (hasApiKey) {
        testGetIt.reset();
      }
    });

    test('Generate and validate schema structure', () {
      final schema = aiGenerator.generateSchema();
      
      expect(schema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
      expect(schema['type'], equals('object'));
      expect(schema['additionalProperties'], equals(false));
      
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('colorPalette'), isTrue);
      expect(properties.containsKey('fontConfiguration'), isTrue);
      
      final colorPalette = properties['colorPalette'] as Map<String, dynamic>;
      final colorProps = colorPalette['properties'] as Map<String, dynamic>;
      final colors = colorProps['colors'] as Map<String, dynamic>;
      final colorItems = colors['items'] as Map<String, dynamic>;
      
      expect(colorItems['pattern'], equals(r'^#[0-9A-Fa-f]{6}$'));
      expect(colors['minItems'], equals(2));
      expect(colors['maxItems'], equals(4));
    }, skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test LLM structured output with color constraints', () async {
      final colorTestSchema = {
        '\$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'}, // ONLY 6-digit hex
            'minItems': 3,
            'maxItems': 3,
            'description': 'Exactly 3 hex colors in #FFFFFF format',
          },
        },
        'required': ['colors'],
        'additionalProperties': false,
      };
      
      final request = LlmRequest(
        systemPrompt: 'You are a color palette generator. Generate exactly 3 colors in hex format.',
        userPrompt: 'Generate 3 beautiful colors for a modern app: one primary, one secondary, one accent.',
        jsonSchema: colorTestSchema,
      );
      
      final response = await llmService.execute(llmConfig, request);
      
      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data.containsKey('colors'), isTrue);
      
      final colors = response.data['colors'] as List;
      expect(colors.length, equals(3));
      
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      for (int i = 0; i < colors.length; i++) {
        final color = colors[i] as String;
        
        expect(color, isA<String>());
        expect(hexPattern.hasMatch(color), isTrue);
        expect(color.length, equals(7));
      }
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test LLM structured output with font weight constraints', () async {
      final fontTestSchema = {
        '\$schema': 'http://json-schema.org/draft-07/schema#',
        'type': 'object',
        'properties': {
          'fontWeights': {
            'type': 'object',
            'properties': {
              'title': {'type': 'integer', 'minimum': 100, 'maximum': 900, 'multipleOf': 100},
              'body': {'type': 'integer', 'minimum': 100, 'maximum': 900, 'multipleOf': 100},
              'caption': {'type': 'integer', 'minimum': 100, 'maximum': 900, 'multipleOf': 100},
            },
            'required': ['title', 'body', 'caption'],
            'additionalProperties': false,
          },
        },
        'required': ['fontWeights'],
        'additionalProperties': false,
      };
      
      final request = LlmRequest(
        systemPrompt: 'You are a typography expert. Generate font weights for different text elements.',
        userPrompt: 'Generate appropriate font weights for title (bold), body (normal), and caption (light) text.',
        jsonSchema: fontTestSchema,
      );
      
      final response = await llmService.execute(llmConfig, request);
      
      final fontWeights = response.data['fontWeights'] as Map<String, dynamic>;
      
      for (final entry in fontWeights.entries) {
        final weight = entry.value as int;
        
        expect(weight, isA<int>());
        expect(weight >= 100, isTrue);
        expect(weight <= 900, isTrue);
        expect(weight % 100, equals(0));
      }
    }, timeout: const Timeout(Duration(seconds: 30)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test complete schema with LLM', () async {
      final schema = aiGenerator.generateSchema();
      
      final request = LlmRequest(
        systemPrompt: '''You are a UI template generator. Create a complete template configuration with:
- A color palette with 3 main colors and 2 neutral colors
- Font configuration with appropriate weights
- Field combinations for a user registration form

Follow the schema constraints exactly.''',
        userPrompt: 'Generate a modern, accessible template for a user registration form.',
        jsonSchema: schema,
      );
      
      final response = await llmService.execute(llmConfig, request);
      
      expect(response.data.containsKey('colorPalette'), isTrue);
      expect(response.data.containsKey('fontConfiguration'), isTrue);
      
      if (response.data.containsKey('colorPalette')) {
        final colorPalette = response.data['colorPalette'] as Map<String, dynamic>;
        
        if (colorPalette.containsKey('colors')) {
          final colors = colorPalette['colors'] as List;
          
          final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
          for (final color in colors) {
            expect(hexPattern.hasMatch(color as String), isTrue);
          }
        }
        
        if (colorPalette.containsKey('neutrals')) {
          final neutrals = colorPalette['neutrals'] as List;
          
          final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
          for (final color in neutrals) {
            expect(hexPattern.hasMatch(color as String), isTrue);
          }
        }
      }
      
      if (response.data.containsKey('fontConfiguration')) {
        final fontConfig = response.data['fontConfiguration'] as Map<String, dynamic>;
        
        for (final entry in fontConfig.entries) {
          if (entry.key.contains('Weight') && entry.value != null) {
            final weight = entry.value as int;
            expect(weight % 100, equals(0));
            expect(weight >= 100 && weight <= 900, isTrue);
          }
        }
      }
    }, timeout: const Timeout(Duration(seconds: 45)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);
  });
}