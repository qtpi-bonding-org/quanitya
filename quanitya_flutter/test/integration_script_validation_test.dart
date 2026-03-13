import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart';

void main() {
  group('Integration Script Validation', () {
    test('End-to-end validation: SymbolicCombinationGenerator → UnifiedSchemaGenerator → AiTemplateGenerator', () {
      // Step 1: Generate all valid combinations from the source of truth
      final symbolGenerator = SymbolicCombinationGenerator();
      final allValidEnumCombinations = symbolGenerator.generateAllValidEnumCombinations();
      
      expect(allValidEnumCombinations.isNotEmpty, isTrue, 
        reason: 'SymbolicCombinationGenerator should produce valid enum combinations');
      
      // Step 2: Verify UnifiedSchemaGenerator can create complete schema from enum combinations
      final unifiedSchemaGenerator = UnifiedSchemaGenerator();
      expect(
        () => unifiedSchemaGenerator.generateSchema(allValidEnumCombinations),
        returnsNormally,
        reason: 'UnifiedSchemaGenerator should create complete schema from enum combinations',
      );
      
      final completeSchema = unifiedSchemaGenerator.generateSchema(allValidEnumCombinations);
      expect(completeSchema, isA<Map<String, dynamic>>());
      expect(completeSchema['\$schema'], equals('http://json-schema.org/draft-07/schema#'));
      expect(completeSchema['properties'], isA<Map<String, dynamic>>());
      
      // Step 3: Verify AiTemplateGenerator orchestrates the entire script
      final aiTemplateGenerator = AiTemplateGenerator(symbolGenerator, unifiedSchemaGenerator);
      expect(
        () => aiTemplateGenerator.generateSchema(),
        returnsNormally,
        reason: 'AiTemplateGenerator should orchestrate the complete script',
      );
      
      final finalSchema = aiTemplateGenerator.generateSchema();
      expect(finalSchema, isA<Map<String, dynamic>>());
      
      // Verify the final schema has all required components
      final properties = finalSchema['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('colorPalette'), isTrue);
      expect(properties.containsKey('fontConfiguration'), isTrue);
      
      // If there are valid combinations, there should be field schemas
      if (allValidEnumCombinations.isNotEmpty) {
        expect(properties.containsKey('fields'), isTrue);
      }
    });
    
    test('Consistency validation: All components use same combination logic', () {
      final symbolGenerator = SymbolicCombinationGenerator();
      
      // Test a few specific combinations to ensure consistency
      final testCombinations = [
        symbolGenerator.generateForFieldType(FieldEnum.integer),
        symbolGenerator.generateForFieldType(FieldEnum.text),
        symbolGenerator.generateForFieldType(FieldEnum.boolean),
      ];
      
      final unifiedSchemaGenerator = UnifiedSchemaGenerator();
      
      for (final combinations in testCombinations) {
        if (combinations.isNotEmpty) {
          // All combinations from SymbolicCombinationGenerator should be processable
          expect(
            () => unifiedSchemaGenerator.generateSchema(combinations),
            returnsNormally,
            reason: 'UnifiedSchemaGenerator should accept all combinations from SymbolicCombinationGenerator',
          );
        }
      }
    });
  });
}
