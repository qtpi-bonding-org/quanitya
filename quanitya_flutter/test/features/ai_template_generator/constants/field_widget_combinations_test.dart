import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ai/field_widget_combinations.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';

void main() {
  group('FieldWidgetCombinations', () {
    test('should have valid combinations for all field types', () {
      // Verify that all AI-generatable FieldEnum values have combinations defined
      // reference is intentionally excluded — not yet supported in AI generation
      for (final fieldType in FieldEnum.values) {
        if (fieldType == FieldEnum.reference) continue;
        if (fieldType == FieldEnum.group) continue;
        final combinations = FieldWidgetCombinations.getValidUiElements(fieldType);
        expect(combinations, isNotEmpty, reason: 'Field type $fieldType should have UI element combinations');
      }
    });

    test('should validate correct field-widget combinations', () {
      // Test some known valid combinations
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.integer, UiElementEnum.slider), isTrue);
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.text, UiElementEnum.textField), isTrue);
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.boolean, UiElementEnum.toggleSwitch), isTrue);
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.enumerated, UiElementEnum.chips), isTrue);
    });

    test('should reject invalid field-widget combinations', () {
      // Test some invalid combinations
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.boolean, UiElementEnum.slider), isFalse);
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.integer, UiElementEnum.chips), isFalse);
      expect(FieldWidgetCombinations.isValidCombination(FieldEnum.text, UiElementEnum.toggleSwitch), isFalse);
    });

    test('should return all valid pairs', () {
      final allPairs = FieldWidgetCombinations.getAllValidPairs();
      expect(allPairs, isNotEmpty);
      
      // Verify that each pair is actually valid
      for (final pair in allPairs) {
        expect(FieldWidgetCombinations.isValidCombination(pair.key, pair.value), isTrue);
      }
    });
  });
}