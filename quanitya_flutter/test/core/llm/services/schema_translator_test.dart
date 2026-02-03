import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/llm/services/schema_translator.dart';

void main() {
  group('Schema Translator Unit Tests', () {
    test('Gemini translator converts unsupported features correctly', () {
      final translator = GeminiSchemaTranslator();
      
      final schema = {
        'type': 'object',
        'properties': {
          'status': {
            'type': 'string',
            'const': 'active' // Should become enum
          },
          'count': {
            'type': 'integer',
            'multipleOf': 3, // Should become enum
            'minimum': 0,
            'maximum': 15
          },
          'category': {
            'oneOf': [ // Should become enum
              {'const': 'urgent'},
              {'const': 'normal'},
            ]
          }
        },
        'required': ['status', 'count', 'category']
      };
      
      final translated = translator.translateSchema(schema);
      
      // Verify const → enum
      expect(translated['properties']['status']['enum'], equals(['active']));
      
      // Verify multipleOf → enum
      final countEnum = translated['properties']['count']['enum'] as List;
      expect(countEnum, equals([0, 3, 6, 9, 12, 15]));
      
      // Verify oneOf → enum
      final categoryEnum = translated['properties']['category']['enum'] as List;
      expect(categoryEnum, equals(['urgent', 'normal']));
    });

    test('OpenAI translator passes schema unchanged', () {
      final translator = OpenAISchemaTranslator();
      
      final schema = {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'const': 'value', // Should be preserved
          'multipleOf': 5, // Should be preserved
        },
      };
      
      final translated = translator.translateSchema(schema);
      expect(translated, equals(schema)); // No changes
    });

    test('Factory selects correct translator by model name', () {
      final testCases = [
        ('google/gemini-pro', GeminiSchemaTranslator),
        ('openai/gpt-4', OpenAISchemaTranslator),
        ('anthropic/claude-3', AnthropicSchemaTranslator),
        ('random-model', OpenAISchemaTranslator), // Default
      ];
      
      for (final (model, expectedType) in testCases) {
        final translator = SchemaTranslatorFactory.getTranslatorForModel(model);
        expect(translator.runtimeType, equals(expectedType));
      }
    });
  });
}