import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_validator_coupling.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';

void main() {
  group('SymbolicCombinationGenerator', () {
    late SymbolicCombinationGenerator generator;

    setUp(() {
      generator = SymbolicCombinationGenerator();
    });

    group('Unit Tests', () {
      test('should generate combinations for all field types', () {
        final combinations = generator.generateAllValidEnumCombinations();
        
        // Should have combinations for all generatable field types
        // reference and group are excluded — no direct UI element
        for (final fieldType in FieldEnum.values) {
          if (fieldType == FieldEnum.reference) continue;
          if (fieldType == FieldEnum.group) continue;
          final fieldCombinations = combinations.where((c) => c.$1 == fieldType);
          expect(
            fieldCombinations.isNotEmpty,
            isTrue,
            reason: 'Should have combinations for field type $fieldType',
          );
        }
      });

      test('should respect UI-validator coupling rules', () {
        final combinations = generator.generateAllValidEnumCombinations();
        
        for (final combination in combinations) {
          final requiredValidators = UiValidatorCoupling.getRequiredValidators(combination.$2);
          
          // All required validators should be present
          for (final requiredValidator in requiredValidators) {
            expect(
              combination.$3.contains(requiredValidator),
              isTrue,
              reason: 'Combination $combination should contain required validator $requiredValidator',
            );
          }
          
          // All validators should be allowed for the UI element
          for (final validator in combination.$3) {
            expect(
              UiValidatorCoupling.isValidCombination(combination.$2, validator),
              isTrue,
              reason: 'Validator $validator should be valid for UI element ${combination.$2}',
            );
          }
        }
      });

      test('should not contain duplicates', () {
        final combinations = generator.generateAllValidEnumCombinations();
        final uniqueCombinations = combinations.toSet();
        
        expect(
          combinations.length,
          equals(uniqueCombinations.length),
          reason: 'Generated combinations should not contain duplicates',
        );
      });

      test('should generate valid field-UI combinations', () {
        // Test specific known valid combinations
        expect(generator.isValidFieldUiCombination(FieldEnum.integer, UiElementEnum.slider), isTrue);
        expect(generator.isValidFieldUiCombination(FieldEnum.float, UiElementEnum.stepper), isTrue);
        expect(generator.isValidFieldUiCombination(FieldEnum.text, UiElementEnum.textField), isTrue);
        expect(generator.isValidFieldUiCombination(FieldEnum.boolean, UiElementEnum.toggleSwitch), isTrue);
        expect(generator.isValidFieldUiCombination(FieldEnum.enumerated, UiElementEnum.dropdown), isTrue);
        expect(generator.isValidFieldUiCombination(FieldEnum.datetime, UiElementEnum.datePicker), isTrue);
        
        // Test specific known invalid combinations
        expect(generator.isValidFieldUiCombination(FieldEnum.boolean, UiElementEnum.slider), isFalse);
        expect(generator.isValidFieldUiCombination(FieldEnum.integer, UiElementEnum.toggleSwitch), isFalse);
        expect(generator.isValidFieldUiCombination(FieldEnum.text, UiElementEnum.datePicker), isFalse);
      });

      test('should generate combinations for specific field types', () {
        // Test integer field combinations
        final integerCombinations = generator.generateForFieldType(FieldEnum.integer);
        expect(integerCombinations.isNotEmpty, isTrue);
        
        for (final combination in integerCombinations) {
          expect(combination.$1, equals(FieldEnum.integer));
          expect(generator.isValidFieldUiCombination(FieldEnum.integer, combination.$2), isTrue);
        }
        
        // Test boolean field combinations
        final booleanCombinations = generator.generateForFieldType(FieldEnum.boolean);
        expect(booleanCombinations.isNotEmpty, isTrue);
        
        for (final combination in booleanCombinations) {
          expect(combination.$1, equals(FieldEnum.boolean));
          expect(generator.isValidFieldUiCombination(FieldEnum.boolean, combination.$2), isTrue);
        }
      });

      test('should provide utility methods for field-UI compatibility', () {
        // Test getValidUiElementsForField
        final integerUiElements = generator.getValidUiElementsForField(FieldEnum.integer);
        expect(integerUiElements, contains(UiElementEnum.slider));
        expect(integerUiElements, contains(UiElementEnum.stepper));
        expect(integerUiElements, contains(UiElementEnum.textField));
        expect(integerUiElements, isNot(contains(UiElementEnum.toggleSwitch)));
        
        // Test getValidFieldTypesForUi
        final sliderFieldTypes = generator.getValidFieldTypesForUi(UiElementEnum.slider);
        expect(sliderFieldTypes, contains(FieldEnum.integer));
        expect(sliderFieldTypes, contains(FieldEnum.float));
        expect(sliderFieldTypes, contains(FieldEnum.dimension));
        expect(sliderFieldTypes, isNot(contains(FieldEnum.boolean)));
        
        // Test getValidCombinationCount
        final count = generator.getValidCombinationCount();
        final actualCombinations = generator.generateAllValidEnumCombinations();
        expect(count, equals(actualCombinations.length));
      });
    });

    group('Property Tests', () {
      const int testIterations = 100; // Property-based testing iterations

      test('Property 2: Symbolic Combination Generation Correctness - **Feature: foundation-enums-coupling, Property 2: Symbolic Combination Generation Correctness** - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**', () {
        // Property: For any generated FieldWidgetSymbol, it should represent a valid 
        // field-UI-validator triplet that respects coupling rules and contains no duplicates
        
        for (int i = 0; i < testIterations; i++) {
          final combinations = generator.generateAllValidEnumCombinations();
          
          // Property 1: All combinations should be valid field-UI pairings (Requirements 3.1)
          for (final combination in combinations) {
            expect(
              generator.isValidFieldUiCombination(combination.$1, combination.$2),
              isTrue,
              reason: 'Generated combination should have valid field-UI pairing: ${combination.$1} + ${combination.$2} (iteration $i)',
            );
          }
          
          // Property 2: All combinations should respect UI-validator coupling rules (Requirements 3.2)
          for (final combination in combinations) {
            final requiredValidators = UiValidatorCoupling.getRequiredValidators(combination.$2);
            
            // All required validators must be present
            for (final requiredValidator in requiredValidators) {
              expect(
                combination.$3.contains(requiredValidator),
                isTrue,
                reason: 'Combination should contain all required validators for UI element ${combination.$2}: expected $requiredValidator (iteration $i)',
              );
            }
            
            // All present validators must be allowed
            for (final validator in combination.$3) {
              expect(
                UiValidatorCoupling.isValidCombination(combination.$2, validator),
                isTrue,
                reason: 'All validators in combination should be valid for UI element ${combination.$2}: $validator (iteration $i)',
              );
            }
          }
          
          // Property 3: All valid permutations should be included without duplicates (Requirements 3.3)
          final uniqueCombinations = combinations.toSet();
          expect(
            combinations.length,
            equals(uniqueCombinations.length),
            reason: 'Generated combinations should not contain duplicates (iteration $i)',
          );
          
          // Property 4: Invalid combinations should be excluded (Requirements 3.4)
          // Verify that no invalid field-UI combinations exist in the results
          for (final combination in combinations) {
            // Check that this combination makes logical sense
            switch (combination.$1) {
              case FieldEnum.boolean:
                expect(
                  combination.$2 == UiElementEnum.toggleSwitch || 
                  combination.$2 == UiElementEnum.checkbox,
                  isTrue,
                  reason: 'Boolean fields should only use boolean UI elements (iteration $i)',
                );
                break;
              case FieldEnum.enumerated:
                expect(
                  combination.$2 == UiElementEnum.dropdown || 
                  combination.$2 == UiElementEnum.radio || 
                  combination.$2 == UiElementEnum.chips,
                  isTrue,
                  reason: 'Enumerated fields should only use selection UI elements (iteration $i)',
                );
                break;
              case FieldEnum.datetime:
                expect(
                  combination.$2 == UiElementEnum.datePicker || 
                  combination.$2 == UiElementEnum.timePicker ||
                  combination.$2 == UiElementEnum.datetimePicker ||
                  combination.$2 == UiElementEnum.textField ||
                  combination.$2 == UiElementEnum.textArea,
                  isTrue,
                  reason: 'DateTime fields should only use date/time or text UI elements (iteration $i)',
                );
                break;
              default:
                // Other field types have more flexible UI element options
                break;
            }
          }
        }
      });

      test('Property 3: Field type coverage completeness', () {
        // Property: Every field type should have at least one valid UI element combination
        
        for (int i = 0; i < testIterations; i++) {
          final combinations = generator.generateAllValidEnumCombinations();
          
          for (final fieldType in FieldEnum.values) {
            // reference and group have no UI combinations — skip
            if (fieldType == FieldEnum.reference) continue;
            if (fieldType == FieldEnum.group) continue;
            final fieldCombinations = combinations.where((c) => c.$1 == fieldType);
            expect(
              fieldCombinations.isNotEmpty,
              isTrue,
              reason: 'Every field type should have at least one valid combination: $fieldType (iteration $i)',
            );
            
            // Verify that generateForFieldType produces the same results
            final specificCombinations = generator.generateForFieldType(fieldType);
            expect(
              specificCombinations.length,
              equals(fieldCombinations.length),
              reason: 'generateForFieldType should produce same count as filtering all combinations for $fieldType (iteration $i)',
            );
          }
        }
      });

      test('Property 4: UI element coverage completeness', () {
        // Property: Every UI element should be used in at least one valid combination
        
        for (int i = 0; i < testIterations; i++) {
          final combinations = generator.generateAllValidEnumCombinations();
          
          for (final uiElement in UiElementEnum.values) {
            final uiCombinations = combinations.where((c) => c.$2 == uiElement);
            expect(
              uiCombinations.isNotEmpty,
              isTrue,
              reason: 'Every UI element should be used in at least one valid combination: $uiElement (iteration $i)',
            );
          }
        }
      });

      test('Property 5: Consistency between utility methods', () {
        // Property: Utility methods should be consistent with main generation logic
        
        for (int i = 0; i < testIterations; i++) {
          final combinations = generator.generateAllValidEnumCombinations();
          
          // Test consistency of getValidCombinationCount
          final count = generator.getValidCombinationCount();
          expect(
            count,
            equals(combinations.length),
            reason: 'getValidCombinationCount should match actual combination count (iteration $i)',
          );
          
          // Test consistency of getValidUiElementsForField
          for (final fieldType in FieldEnum.values) {
            final validUiElements = generator.getValidUiElementsForField(fieldType);
            final actualUiElements = combinations
                .where((c) => c.$1 == fieldType)
                .map((c) => c.$2)
                .toSet()
                .toList();
            
            expect(
              validUiElements.toSet(),
              equals(actualUiElements.toSet()),
              reason: 'getValidUiElementsForField should match actual UI elements for $fieldType (iteration $i)',
            );
          }
          
          // Test consistency of getValidFieldTypesForUi
          for (final uiElement in UiElementEnum.values) {
            final validFieldTypes = generator.getValidFieldTypesForUi(uiElement);
            final actualFieldTypes = combinations
                .where((c) => c.$2 == uiElement)
                .map((c) => c.$1)
                .toSet()
                .toList();
            
            expect(
              validFieldTypes.toSet(),
              equals(actualFieldTypes.toSet()),
              reason: 'getValidFieldTypesForUi should match actual field types for $uiElement (iteration $i)',
            );
          }
        }
      });

      test('Property 6: Deterministic generation', () {
        // Property: Multiple calls should produce identical results
        
        for (int i = 0; i < testIterations; i++) {
          final combinations1 = generator.generateAllValidEnumCombinations();
          final combinations2 = generator.generateAllValidEnumCombinations();
          
          expect(
            combinations1.length,
            equals(combinations2.length),
            reason: 'Multiple calls should produce same number of combinations (iteration $i)',
          );
          
          // Convert to sets for order-independent comparison
          final set1 = combinations1.toSet();
          final set2 = combinations2.toSet();
          
          expect(
            set1,
            equals(set2),
            reason: 'Multiple calls should produce identical combinations (iteration $i)',
          );
        }
      });
    });
  });
}