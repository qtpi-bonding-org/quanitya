import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';

void main() {
  group('AiTemplateGenerator Property Tests', () {
    late AiTemplateGenerator generator;
    const int testIterations = 5; // Property-based testing iterations

    setUp(() {
      final combinationGenerator = SymbolicCombinationGenerator();
      final unifiedSchemaGenerator = UnifiedSchemaGenerator();
      
      generator = AiTemplateGenerator(
        combinationGenerator,
        unifiedSchemaGenerator,
      );
    });

    group('Property 1: Schema generation completeness', () {
      test('**Feature: integration-end-to-end-script, Property 1: Schema generation completeness** - **Validates: Requirements 1.1, 1.2, 1.3, 1.4**', () {
        for (int i = 0; i < testIterations; i++) {
          // Generate schema
          final schema = generator.generateSchema();
          
          // Verify schema is not null and is a Map
          expect(schema, isNotNull);
          expect(schema, isA<Map<String, dynamic>>());
          
          // Verify schema has required top-level structure
          expect(schema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
          expect(schema['type'], equals('object'));
          expect(schema['properties'], isA<Map<String, dynamic>>());
          expect(schema['additionalProperties'], equals(false));
          
          final properties = schema['properties'] as Map<String, dynamic>;
          
          // Verify field schemas are included (Requirements 1.1, 1.2, 1.3, 1.4)
          // Field schemas should be present when there are valid combinations
          // Fields is an array schema (supports 1-10 fields per template)
          if (properties.containsKey('fields')) {
            expect(properties['fields'], isA<Map<String, dynamic>>());
            final fieldSchema = properties['fields'] as Map<String, dynamic>;
            expect(fieldSchema['type'], equals('array'));
            expect(fieldSchema['items'], isA<Map<String, dynamic>>());
            expect(fieldSchema['minItems'], equals(1));
            expect(fieldSchema['maxItems'], equals(10));
          }
          
          // Verify color palette constraints are included (Requirements 1.1, 1.2, 1.3, 1.4)
          expect(properties['colorPalette'], isA<Map<String, dynamic>>());
          final colorPaletteSchema = properties['colorPalette'] as Map<String, dynamic>;
          expect(colorPaletteSchema['type'], equals('object'));
          expect(colorPaletteSchema['properties'], isA<Map<String, dynamic>>());
          
          final colorProperties = colorPaletteSchema['properties'] as Map<String, dynamic>;
          expect(colorProperties['colors'], isA<Map<String, dynamic>>());
          expect(colorProperties['neutrals'], isA<Map<String, dynamic>>());
          
          // Verify font configuration constraints are included (Requirements 1.1, 1.2, 1.3, 1.4)
          expect(properties['fontConfiguration'], isA<Map<String, dynamic>>());
          final fontConfigSchema = properties['fontConfiguration'] as Map<String, dynamic>;
          expect(fontConfigSchema['type'], equals('object'));
          expect(fontConfigSchema['properties'], isA<Map<String, dynamic>>());
          
          final fontProperties = fontConfigSchema['properties'] as Map<String, dynamic>;
          expect(fontProperties['titleFontFamily'], isA<Map<String, dynamic>>());
          expect(fontProperties['subtitleFontFamily'], isA<Map<String, dynamic>>());
          expect(fontProperties['bodyFontFamily'], isA<Map<String, dynamic>>());
          expect(fontProperties['titleWeight'], isA<Map<String, dynamic>>());
          expect(fontProperties['subtitleWeight'], isA<Map<String, dynamic>>());
          expect(fontProperties['bodyWeight'], isA<Map<String, dynamic>>());
        }
      });
    });

    group('Property 2: Schema generation consistency', () {
      test('**Feature: integration-end-to-end-script, Property 2: Schema generation consistency**', () {
        for (int i = 0; i < testIterations; i++) {
          // Generate schema twice
          final schema1 = generator.generateSchema();
          final schema2 = generator.generateSchema();
          
          // Verify schemas are structurally identical
          expect(schema1['\$schema'], equals(schema2['\$schema']));
          expect(schema1['type'], equals(schema2['type']));
          expect(schema1['additionalProperties'], equals(schema2['additionalProperties']));
          
          final props1 = schema1['properties'] as Map<String, dynamic>;
          final props2 = schema2['properties'] as Map<String, dynamic>;
          
          expect(props1.keys.toSet(), equals(props2.keys.toSet()));
        }
      });
    });
  });
}
