import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/infrastructure/auth/auth_account_orchestrator.dart';
import 'package:quanitya_flutter/infrastructure/llm/services/llm_service.dart';
import 'package:quanitya_flutter/infrastructure/llm/models/llm_types.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import 'live_api_test_helper.dart';

class _MockAuthOrchestrator extends Mock implements AuthAccountOrchestrator {}

@Tags(['live_api'])
void main() {
  group('Constraint Enforcement Proof Tests', () {
    late GetIt testGetIt;
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
      testGetIt.registerLazySingleton<Client>(() => Client('http://localhost:8080/'));
      testGetIt.registerLazySingleton<LlmService>(
        () => LlmService(testGetIt<http.Client>(), testGetIt<Client>(), _MockAuthOrchestrator()),
      );
      
      llmService = testGetIt<LlmService>();
      llmConfig = LlmConfig.openRouter(
        apiKey: apiKey,
        model: 'openai/gpt-4o-mini', // Known to support structured output
        appName: 'Constraint Enforcement Proof',
        appUrl: 'https://github.com/qtpi-bonding/quanitya_flutter',
      );
      
      print('✅ Testing constraint enforcement with: ${llmConfig.model}');
    });

    tearDownAll(() {
      if (hasApiKey) {
        testGetIt.reset();
      }
    });

    test('PROOF: Strict hex color constraint enforcement', () async {
      print('\n🎯 PROVING: Hex color constraints are ENFORCED, not just hints');
      
      // Create a schema that ONLY allows 6-digit hex colors
      final strictColorSchema = {
        'type': 'object',
        'properties': {
          'colors': {
            'type': 'array',
            'items': {
              'type': 'string',
              'pattern': r'^#[0-9A-Fa-f]{6}$', // ONLY 6-digit hex
            },
            'minItems': 3,
            'maxItems': 3,
          },
        },
        'required': ['colors'],
        'additionalProperties': false,
      };
      
      // Ask for something that would normally generate #FFF (3-digit)
      final request = LlmRequest(
        systemPrompt: 'You are a color generator. Generate colors in the most common short format.',
        userPrompt: 'Generate 3 colors: white, black, and red. Use the shortest possible format.',
        jsonSchema: strictColorSchema,
      );
      
      print('📤 Asking for SHORT format colors (would normally be #FFF, #000, #F00)');
      print('🔒 Schema ENFORCES 6-digit format only');
      
      final response = await llmService.execute(llmConfig, request);
      
      print('📥 LLM Response:');
      print(JsonEncoder.withIndent('  ').convert(response.data));
      
      final colors = response.data['colors'] as List;
      expect(colors.length, equals(3));
      
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
      
      for (int i = 0; i < colors.length; i++) {
        final color = colors[i] as String;
        print('🎨 Color ${i + 1}: $color');
        
        // CRITICAL TEST: Must be exactly 6 digits, not 3
        expect(color.length, equals(7), 
          reason: 'Color "$color" must be exactly 7 characters (#FFFFFF)');
        expect(hexPattern.hasMatch(color), isTrue, 
          reason: 'Color "$color" must match 6-digit hex pattern');
        expect(color, isNot(matches(r'^#[0-9A-Fa-f]{3}$')), 
          reason: 'Color "$color" must NOT be 3-digit format');
      }
      
      print('✅ PROOF SUCCESSFUL: LLM was FORCED to use 6-digit format');
      print('🎯 Even when asked for "shortest format", schema constraints were ENFORCED');
    }, skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('PROOF: Font weight multiple constraint enforcement', () async {
      print('\n🎯 PROVING: Font weight multipleOf constraints are ENFORCED');
      
      final strictFontSchema = {
        'type': 'object',
        'properties': {
          'fontWeights': {
            'type': 'object',
            'properties': {
              'light': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100, // MUST be multiple of 100
              },
              'normal': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100,
              },
              'bold': {
                'type': 'integer',
                'minimum': 100,
                'maximum': 900,
                'multipleOf': 100,
              },
            },
            'required': ['light', 'normal', 'bold'],
            'additionalProperties': false,
          },
        },
        'required': ['fontWeights'],
        'additionalProperties': false,
      };
      
      // Ask for weights that would normally be non-multiples of 100
      final request = LlmRequest(
        systemPrompt: 'You are a typography expert. Use precise, fine-tuned font weights.',
        userPrompt: 'Generate font weights: light (around 350), normal (around 450), bold (around 650). Be precise and specific.',
        jsonSchema: strictFontSchema,
      );
      
      print('📤 Asking for PRECISE weights (would normally be 350, 450, 650)');
      print('🔒 Schema ENFORCES multipleOf 100 only');
      
      final response = await llmService.execute(llmConfig, request);
      
      print('📥 Font Weight Response:');
      print(JsonEncoder.withIndent('  ').convert(response.data));
      
      final fontWeights = response.data['fontWeights'] as Map<String, dynamic>;
      
      for (final entry in fontWeights.entries) {
        final weight = entry.value as int;
        print('📝 ${entry.key}: $weight');
        
        // CRITICAL TEST: Must be multiple of 100
        expect(weight % 100, equals(0), 
          reason: 'Weight $weight must be multiple of 100');
        expect(weight >= 100 && weight <= 900, isTrue,
          reason: 'Weight $weight must be between 100-900');
        
        // Verify it's NOT the "precise" values we asked for
        expect(weight, isNot(anyOf([350, 450, 650])),
          reason: 'Weight $weight should be rounded to multiple of 100, not precise value');
      }
      
      print('✅ PROOF SUCCESSFUL: LLM was FORCED to use multiples of 100');
      print('🎯 Even when asked for "precise" weights, schema constraints were ENFORCED');
    }, skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);

    test('PROOF: Array length constraint enforcement', () async {
      print('\n🎯 PROVING: Array length constraints are ENFORCED');
      
      final strictArraySchema = {
        'type': 'object',
        'properties': {
          'items': {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 5,
            'maxItems': 5, // EXACTLY 5 items required
          },
        },
        'required': ['items'],
        'additionalProperties': false,
      };
      
      // Ask for a different number of items
      final request = LlmRequest(
        systemPrompt: 'You are helpful but tend to provide extra information.',
        userPrompt: 'Give me 3 programming languages. Just 3, no more.',
        jsonSchema: strictArraySchema,
      );
      
      print('📤 Asking for EXACTLY 3 items');
      print('🔒 Schema ENFORCES exactly 5 items');
      
      final response = await llmService.execute(llmConfig, request);
      
      print('📥 Array Response:');
      print(JsonEncoder.withIndent('  ').convert(response.data));
      
      final items = response.data['items'] as List;
      print('📊 Received ${items.length} items');
      
      // CRITICAL TEST: Must be exactly 5, not 3 as requested
      expect(items.length, equals(5), 
        reason: 'Array must have exactly 5 items as enforced by schema');
      expect(items.length, isNot(equals(3)),
        reason: 'Array should NOT have 3 items as requested in prompt');
      
      print('✅ PROOF SUCCESSFUL: LLM was FORCED to provide 5 items');
      print('🎯 Even when asked for 3 items, schema constraint ENFORCED 5 items');
    }, skip: !hasApiKey ? 'OPENROUTER_API_KEY not found in .env' : null);
  });
}