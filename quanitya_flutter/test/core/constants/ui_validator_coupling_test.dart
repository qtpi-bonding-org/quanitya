import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_validator_coupling.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';

void main() {
  group('UiValidatorCoupling', () {
    group('Unit Tests', () {
      test('should have coupling rules defined for all UI elements', () {
        // Verify that all UiElementEnum values have coupling rules defined
        for (final uiElement in UiElementEnum.values) {
          expect(
            UiValidatorCoupling.allowedValidators.containsKey(uiElement),
            isTrue,
            reason: 'UI element $uiElement should have allowed validators defined',
          );
          expect(
            UiValidatorCoupling.requiredValidators.containsKey(uiElement),
            isTrue,
            reason: 'UI element $uiElement should have required validators defined',
          );
        }
      });

      test('should enforce numeric validators for numeric UI elements', () {
        // Requirements 2.1: slider requires numeric validators with min, max, and step properties
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.slider),
          contains(ValidatorType.numeric),
        );
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.stepper),
          contains(ValidatorType.numeric),
        );
        
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.slider, ValidatorType.numeric),
          isTrue,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.stepper, ValidatorType.numeric),
          isTrue,
        );
      });

      test('should enforce enumerated validators for selection UI elements', () {
        // Requirements 2.2: dropdown requires enumerated validators with options property
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.dropdown),
          contains(ValidatorType.enumerated),
        );
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.radio),
          contains(ValidatorType.enumerated),
        );
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.chips),
          contains(ValidatorType.enumerated),
        );
        
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.dropdown, ValidatorType.enumerated),
          isTrue,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.radio, ValidatorType.enumerated),
          isTrue,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.chips, ValidatorType.enumerated),
          isTrue,
        );
      });

      test('should allow text validators for text UI elements', () {
        // Requirements 2.3: textField allows text validators with length and pattern properties
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.textField, ValidatorType.text),
          isTrue,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.textArea, ValidatorType.text),
          isTrue,
        );
        
        // Text validators are optional for text fields
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.textField),
          isEmpty,
        );
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.textArea),
          isEmpty,
        );
      });

      test('should require no validators for boolean UI elements', () {
        // Requirements 2.4: toggleSwitch requires no validators
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.toggleSwitch),
          isEmpty,
        );
        expect(
          UiValidatorCoupling.getRequiredValidators(UiElementEnum.checkbox),
          isEmpty,
        );
        
        // Boolean elements should only allow optional validators
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.toggleSwitch, ValidatorType.optional),
          isTrue,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.checkbox, ValidatorType.optional),
          isTrue,
        );
      });

      test('should reject invalid UI-validator combinations', () {
        // Requirements 2.5: invalid combinations should be prevented
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.slider, ValidatorType.text),
          isFalse,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.dropdown, ValidatorType.numeric),
          isFalse,
        );
        expect(
          UiValidatorCoupling.isValidCombination(UiElementEnum.toggleSwitch, ValidatorType.enumerated),
          isFalse,
        );
      });

      test('should validate required validators correctly', () {
        expect(
          UiValidatorCoupling.hasAllRequiredValidators(
            UiElementEnum.slider,
            [ValidatorType.numeric],
          ),
          isTrue,
        );
        
        expect(
          UiValidatorCoupling.hasAllRequiredValidators(
            UiElementEnum.slider,
            [],
          ),
          isFalse,
        );
        
        expect(
          UiValidatorCoupling.hasAllRequiredValidators(
            UiElementEnum.toggleSwitch,
            [],
          ),
          isTrue, // No required validators
        );
      });

      test('should validate allowed validators correctly', () {
        expect(
          UiValidatorCoupling.areAllValidatorsAllowed(
            UiElementEnum.slider,
            [ValidatorType.numeric, ValidatorType.optional],
          ),
          isTrue,
        );
        
        expect(
          UiValidatorCoupling.areAllValidatorsAllowed(
            UiElementEnum.slider,
            [ValidatorType.text],
          ),
          isFalse,
        );
      });

      test('should find UI elements requiring specific validators', () {
        final numericElements = UiValidatorCoupling.getUiElementsRequiring(ValidatorType.numeric);
        expect(numericElements, contains(UiElementEnum.slider));
        expect(numericElements, contains(UiElementEnum.stepper));
        
        final enumeratedElements = UiValidatorCoupling.getUiElementsRequiring(ValidatorType.enumerated);
        expect(enumeratedElements, contains(UiElementEnum.dropdown));
        expect(enumeratedElements, contains(UiElementEnum.radio));
        expect(enumeratedElements, contains(UiElementEnum.chips));
      });

      test('should find UI elements allowing specific validators', () {
        final optionalElements = UiValidatorCoupling.getUiElementsAllowing(ValidatorType.optional);
        expect(optionalElements, isNotEmpty);
        expect(optionalElements, contains(UiElementEnum.slider));
        expect(optionalElements, contains(UiElementEnum.toggleSwitch));
        
        final textElements = UiValidatorCoupling.getUiElementsAllowing(ValidatorType.text);
        expect(textElements, contains(UiElementEnum.textField));
        expect(textElements, contains(UiElementEnum.textArea));
      });
    });

    group('Property Tests', () {
      const int testIterations = 1;

      test('Property 1: UI-Validator Coupling Enforcement - **Feature: foundation-enums-coupling, Property 1: UI-Validator Coupling Enforcement** - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**', () {
        // Property: For any UiElementEnum and ValidatorType combination, the coupling system 
        // should correctly identify valid and invalid pairings according to the defined rules
        
        for (int i = 0; i < testIterations; i++) {
          // Generate all possible UI element and validator type combinations
          for (final uiElement in UiElementEnum.values) {
            for (final validatorType in ValidatorType.values) {
              final isValid = UiValidatorCoupling.isValidCombination(uiElement, validatorType);
              final allowedValidators = UiValidatorCoupling.getAllowedValidators(uiElement);
              
              // Property: isValidCombination should return true if and only if 
              // the validator type is in the allowed validators list
              expect(
                isValid,
                equals(allowedValidators.contains(validatorType)),
                reason: 'isValidCombination($uiElement, $validatorType) should match allowedValidators.contains() (iteration $i)',
              );
              
              // Property: If a validator is required, it must also be allowed
              final requiredValidators = UiValidatorCoupling.getRequiredValidators(uiElement);
              if (requiredValidators.contains(validatorType)) {
                expect(
                  allowedValidators.contains(validatorType),
                  isTrue,
                  reason: 'Required validator $validatorType for $uiElement must also be allowed (iteration $i)',
                );
              }
            }
          }
        }
      });

      test('Property 2: Required validators consistency', () {
        // Property: All required validators must be a subset of allowed validators
        
        for (int i = 0; i < testIterations; i++) {
          for (final uiElement in UiElementEnum.values) {
            final required = UiValidatorCoupling.getRequiredValidators(uiElement);
            final allowed = UiValidatorCoupling.getAllowedValidators(uiElement);
            
            // Property: Every required validator must be in the allowed list
            for (final requiredValidator in required) {
              expect(
                allowed.contains(requiredValidator),
                isTrue,
                reason: 'Required validator $requiredValidator for $uiElement must be in allowed list (iteration $i)',
              );
            }
            
            // Property: hasAllRequiredValidators should return true when all required validators are present
            expect(
              UiValidatorCoupling.hasAllRequiredValidators(uiElement, required),
              isTrue,
              reason: 'hasAllRequiredValidators should return true when all required validators are provided (iteration $i)',
            );
            
            // Property: areAllValidatorsAllowed should return true for allowed validators
            expect(
              UiValidatorCoupling.areAllValidatorsAllowed(uiElement, allowed),
              isTrue,
              reason: 'areAllValidatorsAllowed should return true for all allowed validators (iteration $i)',
            );
          }
        }
      });

      test('Property 3: Coupling rules enforcement', () {
        // Property: Specific coupling rules must be enforced according to requirements
        
        for (int i = 0; i < testIterations; i++) {
          // Property: Numeric UI elements must require numeric validators (Requirements 2.1)
          final numericUiElements = [UiElementEnum.slider, UiElementEnum.stepper];
          for (final uiElement in numericUiElements) {
            final required = UiValidatorCoupling.getRequiredValidators(uiElement);
            expect(
              required.contains(ValidatorType.numeric),
              isTrue,
              reason: 'Numeric UI element $uiElement must require numeric validators (iteration $i)',
            );
          }
          
          // Property: Selection UI elements must require enumerated validators (Requirements 2.2)
          final selectionUiElements = [UiElementEnum.dropdown, UiElementEnum.radio, UiElementEnum.chips];
          for (final uiElement in selectionUiElements) {
            final required = UiValidatorCoupling.getRequiredValidators(uiElement);
            expect(
              required.contains(ValidatorType.enumerated),
              isTrue,
              reason: 'Selection UI element $uiElement must require enumerated validators (iteration $i)',
            );
          }
          
          // Property: Boolean UI elements must not require any validators (Requirements 2.4)
          final booleanUiElements = [UiElementEnum.toggleSwitch, UiElementEnum.checkbox];
          for (final uiElement in booleanUiElements) {
            final required = UiValidatorCoupling.getRequiredValidators(uiElement);
            expect(
              required.isEmpty,
              isTrue,
              reason: 'Boolean UI element $uiElement must not require any validators (iteration $i)',
            );
          }
          
          // Property: Text UI elements should allow but not require text validators (Requirements 2.3)
          final textUiElements = [UiElementEnum.textField, UiElementEnum.textArea];
          for (final uiElement in textUiElements) {
            final required = UiValidatorCoupling.getRequiredValidators(uiElement);
            final allowed = UiValidatorCoupling.getAllowedValidators(uiElement);
            
            expect(
              required.contains(ValidatorType.text),
              isFalse,
              reason: 'Text UI element $uiElement should not require text validators (iteration $i)',
            );
            expect(
              allowed.contains(ValidatorType.text),
              isTrue,
              reason: 'Text UI element $uiElement should allow text validators (iteration $i)',
            );
          }
        }
      });

      test('Property 4: Bidirectional lookup consistency', () {
        // Property: Bidirectional lookups should be consistent
        
        for (int i = 0; i < testIterations; i++) {
          for (final validatorType in ValidatorType.values) {
            // Property: If getUiElementsRequiring returns a UI element, 
            // that UI element should require the validator type
            final requiringElements = UiValidatorCoupling.getUiElementsRequiring(validatorType);
            for (final uiElement in requiringElements) {
              final required = UiValidatorCoupling.getRequiredValidators(uiElement);
              expect(
                required.contains(validatorType),
                isTrue,
                reason: 'UI element $uiElement returned by getUiElementsRequiring($validatorType) should require that validator (iteration $i)',
              );
            }
            
            // Property: If getUiElementsAllowing returns a UI element,
            // that UI element should allow the validator type
            final allowingElements = UiValidatorCoupling.getUiElementsAllowing(validatorType);
            for (final uiElement in allowingElements) {
              final allowed = UiValidatorCoupling.getAllowedValidators(uiElement);
              expect(
                allowed.contains(validatorType),
                isTrue,
                reason: 'UI element $uiElement returned by getUiElementsAllowing($validatorType) should allow that validator (iteration $i)',
              );
            }
          }
        }
      });
    });
  });
}