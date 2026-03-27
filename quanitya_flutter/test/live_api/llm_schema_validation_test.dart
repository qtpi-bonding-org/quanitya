import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/infrastructure/auth/auth_account_orchestrator.dart';
import 'package:quanitya_flutter/logic/templates/enums/measurement_unit.dart';
import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/infrastructure/llm/services/llm_service.dart';
import 'package:quanitya_flutter/infrastructure/llm/models/llm_types.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import 'live_api_test_helper.dart';

class _MockAuthOrchestrator extends Mock implements AuthAccountOrchestrator {}

@Tags(['live_api'])
void main() {
  // Load env synchronously so skip: checks work at test registration time
  LiveApiTestHelper.loadEnvSync();
  final hasApiKey = LiveApiTestHelper.hasOpenRouterKey;

  group('LLM Schema Validation Tests', () {
    late GetIt testGetIt;
    late AiTemplateGenerator aiGenerator;
    late LlmService llmService;
    late LlmConfig llmConfig;

    setUpAll(() async {
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
      testGetIt.registerLazySingleton<LlmService>(() => LlmService(testGetIt<http.Client>(), testGetIt<Client>(), _MockAuthOrchestrator()));
      
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

    test('Test complete schema with real template prompt', () async {
      final schema = aiGenerator.generateSchema();

      // Load the real prompt from assets
      final promptFile = File('assets/template_prompt.json');
      expect(promptFile.existsSync(), isTrue,
          reason: 'assets/template_prompt.json must exist');
      final promptConfig = jsonDecode(promptFile.readAsStringSync()) as Map<String, dynamic>;
      final systemPrompt = promptConfig['system_prompt'] as String;

      final request = LlmRequest(
        systemPrompt: systemPrompt,
        userPrompt: 'Create a daily mood and energy tracker with sliders for mood (1-10) and energy (1-10), plus a notes field.',
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
    }, timeout: const Timeout(Duration(seconds: 90)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test LLM generates dimension fields with valid measurement units', () async {
      final schema = aiGenerator.generateSchema();

      final request = LlmRequest(
        systemPrompt: '''You are a fitness template generator. Create a template that tracks physical measurements.
You MUST include dimension fields with units. Use fieldType "dimension" for any measurement that has a unit (weight, distance, volume, etc.).
Each dimension field requires a "unit" value from the allowed enum.

Follow the schema constraints exactly.''',
        userPrompt: 'Create a workout tracker with: body weight (kg), run distance (km), water intake (mL), and rest time (minutes).',
        jsonSchema: schema,
      );

      final response = await llmService.execute(llmConfig, request);

      expect(response.data.containsKey('fields'), isTrue);
      final fields = response.data['fields'] as List;
      expect(fields, isNotEmpty);

      // Collect all valid MeasurementUnit names
      final validUnits = MeasurementUnit.values.map((u) => u.name).toSet();

      // Find dimension fields and verify they have valid units
      final dimensionFields = fields
          .cast<Map<String, dynamic>>()
          .where((f) => f['fieldType'] == 'dimension')
          .toList();

      expect(dimensionFields, isNotEmpty,
          reason: 'LLM should generate at least one dimension field for a workout tracker');

      for (final field in dimensionFields) {
        final label = field['label'] as String;
        expect(field.containsKey('unit'), isTrue,
            reason: 'Dimension field "$label" must have a unit');

        final unit = field['unit'] as String;
        expect(validUnits.contains(unit), isTrue,
            reason: 'Unit "$unit" on field "$label" must be a valid MeasurementUnit enum value. '
                'Valid values: $validUnits');
      }
    }, timeout: const Timeout(Duration(seconds: 45)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test LLM generates enumerated fields with valid options', () async {
      final schema = aiGenerator.generateSchema();

      final request = LlmRequest(
        systemPrompt: '''You are a health tracker template generator.
You MUST include enumerated fields with options. Use fieldType "enumerated" for any field where the user picks from a predefined list.
Each enumerated field requires an "options" array of string values.

Follow the schema constraints exactly.''',
        userPrompt: 'Create a daily wellness tracker with: mood (happy, neutral, sad, anxious, energetic), sleep quality (poor, fair, good, excellent), and exercise type (running, cycling, swimming, yoga, weights, none).',
        jsonSchema: schema,
      );

      final response = await llmService.execute(llmConfig, request);

      expect(response.data.containsKey('fields'), isTrue);
      final fields = response.data['fields'] as List;
      expect(fields, isNotEmpty);

      final enumeratedFields = fields
          .cast<Map<String, dynamic>>()
          .where((f) => f['fieldType'] == 'enumerated')
          .toList();

      expect(enumeratedFields, isNotEmpty,
          reason: 'LLM should generate at least one enumerated field for a wellness tracker');

      for (final field in enumeratedFields) {
        final label = field['label'] as String;
        expect(field.containsKey('options'), isTrue,
            reason: 'Enumerated field "$label" must have options');

        final options = field['options'] as List;
        expect(options.length, greaterThanOrEqualTo(2),
            reason: 'Enumerated field "$label" must have at least 2 options');

        for (final option in options) {
          expect(option, isA<String>(),
              reason: 'Each option in "$label" must be a string');
          expect((option as String).isNotEmpty,
              isTrue,
              reason: 'Options in "$label" must not be empty');
        }
      }
    }, timeout: const Timeout(Duration(seconds: 45)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test analysis prompt generates valid JS script for numeric field', () async {
      // Load the real analysis prompt
      final promptFile = File('assets/prompt.json');
      expect(promptFile.existsSync(), isTrue,
          reason: 'assets/prompt.json must exist');
      final promptConfig = jsonDecode(promptFile.readAsStringSync()) as Map<String, dynamic>;

      // Render the Jinja2 template with test values
      final systemPromptTemplate = promptConfig['system_prompt'] as String;
      final systemPrompt = systemPromptTemplate
          .replaceAll('{{ user_intent }}', 'Calculate basic statistics for my mood scores')
          .replaceAll('{{ value_shape }}', 'number[] (integers from 1-10)');

      // Extract inner schema (LlmService expects raw JSON Schema, not OpenAI wrapper)
      final schemaWrapper = promptConfig['json_schema'] as Map<String, dynamic>;
      final jsonSchema = schemaWrapper['schema'] as Map<String, dynamic>;

      final request = LlmRequest(
        systemPrompt: systemPrompt,
        userPrompt: 'Calculate basic statistics for my mood scores',
        jsonSchema: jsonSchema,
      );

      final response = await llmService.execute(llmConfig, request);

      expect(response.data.containsKey('insight_name'), isTrue);
      expect(response.data.containsKey('output_mode'), isTrue);
      expect(response.data.containsKey('logic_fragment'), isTrue);
      expect(response.data.containsKey('reasoning'), isTrue);

      final outputMode = response.data['output_mode'] as String;
      expect(['scalar', 'vector', 'matrix'], contains(outputMode));

      final logicFragment = response.data['logic_fragment'] as String;
      expect(logicFragment, isNotEmpty);
      // Should reference data.values since we told it the shape is number[]
      expect(logicFragment.contains('data.values') || logicFragment.contains('data.timestamps'),
          isTrue,
          reason: 'Script should use the data API');
    }, timeout: const Timeout(Duration(seconds: 45)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('Test analysis prompt generates valid JS script for group field', () async {
      // Load the real analysis prompt
      final promptFile = File('assets/prompt.json');
      final promptConfig = jsonDecode(promptFile.readAsStringSync()) as Map<String, dynamic>;

      final systemPromptTemplate = promptConfig['system_prompt'] as String;
      final systemPrompt = systemPromptTemplate
          .replaceAll('{{ user_intent }}', 'Find my max bench press weight across all sessions')
          .replaceAll('{{ value_shape }}', '{exercise: string, weight: number, reps: number}[][] (array of arrays of set objects per entry)');

      // Extract inner schema
      final schemaWrapper = promptConfig['json_schema'] as Map<String, dynamic>;
      final jsonSchema = schemaWrapper['schema'] as Map<String, dynamic>;

      final request = LlmRequest(
        systemPrompt: systemPrompt,
        userPrompt: 'Find my max bench press weight across all sessions',
        jsonSchema: jsonSchema,
      );

      final response = await llmService.execute(llmConfig, request);

      expect(response.data.containsKey('logic_fragment'), isTrue);

      final logicFragment = response.data['logic_fragment'] as String;
      expect(logicFragment, isNotEmpty);
      // Should reference filtering or accessing group properties
      expect(
        logicFragment.contains('data.values') ||
        logicFragment.contains('weight') ||
        logicFragment.contains('bench') ||
        logicFragment.contains('Bench'),
        isTrue,
        reason: 'Script should work with group field data shape',
      );
    }, timeout: const Timeout(Duration(seconds: 45)), skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);
  });
}