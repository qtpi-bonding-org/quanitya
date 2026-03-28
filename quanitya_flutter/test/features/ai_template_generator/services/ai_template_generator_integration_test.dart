import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_widget_symbol.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';
import 'package:quanitya_flutter/logic/templates/exceptions/template_generation_exception.dart';

void main() {
  group('AiTemplateGenerator Integration Tests', () {
    late GetIt testGetIt;
    late AiTemplateGenerator generator;

    setUpAll(() {
      testGetIt = GetIt.asNewInstance();
      
      testGetIt.registerLazySingleton<SymbolicCombinationGenerator>(
        () => SymbolicCombinationGenerator(),
      );
      
      testGetIt.registerFactory<UnifiedSchemaGenerator>(
        () => UnifiedSchemaGenerator(),
      );
      
      testGetIt.registerFactory<AiTemplateGenerator>(
        () => AiTemplateGenerator(
          testGetIt<SymbolicCombinationGenerator>(),
          testGetIt<UnifiedSchemaGenerator>(),
        ),
      );
      
      generator = testGetIt<AiTemplateGenerator>();
    });

    tearDownAll(() {
      testGetIt.reset();
    });

    group('Schema Generation Script', () {
      test('generateSchema() produces valid JSON Schema', () {
        final schema = generator.generateSchema();
        
        expect(schema, isNotNull);
        expect(schema, isA<Map<String, dynamic>>());
        expect(schema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
        
        final properties = schema['properties'] as Map<String, dynamic>;
        expect(properties['colorPalette'], isNotNull);
        expect(properties['fontConfiguration'], isNotNull);
      });

      test('Schema contains field definitions when combinations exist', () {
        final schema = generator.generateSchema();
        final properties = schema['properties'] as Map<String, dynamic>;
        
        if (properties.containsKey('fields')) {
          expect(properties['fields'], isA<Map<String, dynamic>>());
          final fieldSchema = properties['fields'] as Map<String, dynamic>;
          expect(fieldSchema['type'], equals('array'));
          expect(fieldSchema['items'], isA<Map<String, dynamic>>());
          expect(fieldSchema['minItems'], equals(1));
          expect(fieldSchema['maxItems'], equals(10));
        }
      });

      test('Schema contains color palette constraints', () {
        final schema = generator.generateSchema();
        final properties = schema['properties'] as Map<String, dynamic>;
        
        expect(properties['colorPalette'], isA<Map<String, dynamic>>());
        final colorPaletteSchema = properties['colorPalette'] as Map<String, dynamic>;
        expect(colorPaletteSchema['type'], equals('object'));
        expect(colorPaletteSchema['properties'], isA<Map<String, dynamic>>());
        
        final colorProperties = colorPaletteSchema['properties'] as Map<String, dynamic>;
        expect(colorProperties['colors'], isA<Map<String, dynamic>>());
        expect(colorProperties['neutrals'], isA<Map<String, dynamic>>());
      });

      test('Schema contains font configuration constraints', () {
        final schema = generator.generateSchema();
        final properties = schema['properties'] as Map<String, dynamic>;
        
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
      });
    });

    group('Error Scenarios and Exception Mapping', () {
      test('Schema generation exceptions', () {
        final mockGenerator = _MockFailingSymbolicGenerator();
        final mockUnifiedGenerator = UnifiedSchemaGenerator();
        final failingAiGenerator = AiTemplateGenerator(
          mockGenerator,
          mockUnifiedGenerator,
        );
        
        expect(
          () => failingAiGenerator.generateSchema(),
          throwsA(isA<TemplateGenerationException>()),
        );
      });
    });

  });
}

class _MockFailingSymbolicGenerator extends SymbolicCombinationGenerator {
  @override
  List<(FieldEnum, UiElementEnum, List<ValidatorType>)> generateAllValidEnumCombinations() {
    throw Exception('Mock failure for testing');
  }
  
  @override
  List<FieldWidgetSymbol> generateAllValidCombinations() {
    throw Exception('Mock failure for testing');
  }
}
