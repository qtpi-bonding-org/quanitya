import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/enums/ui_element_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_widget_symbol.dart';

void main() {
  group('FieldWidgetSymbol', () {
    group('Basic Construction', () {
      test('should create a basic symbol with required fields', () {
        final symbol = FieldWidgetSymbol(
          fieldType: FieldEnum.text,
          uiElement: UiElementEnum.textField,
          requiredValidators: const [ValidatorType.text],
        );

        expect(symbol.fieldType, equals(FieldEnum.text));
        expect(symbol.uiElement, equals(UiElementEnum.textField));
        expect(symbol.requiredValidators, equals([ValidatorType.text]));
      });

      test('should support empty validator list', () {
        final symbol = FieldWidgetSymbol(
          fieldType: FieldEnum.boolean,
          uiElement: UiElementEnum.toggleSwitch,
          requiredValidators: const [],
        );

        expect(symbol.requiredValidators, isEmpty);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final symbol = FieldWidgetSymbol(
          fieldType: FieldEnum.integer,
          uiElement: UiElementEnum.slider,
          requiredValidators: const [ValidatorType.numeric],
        );

        final json = symbol.toJson();

        expect(json['fieldType'], equals('integer'));
        expect(json['uiElement'], equals('slider'));
        expect(json['requiredValidators'], equals(['numeric']));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'fieldType': 'float',
          'uiElement': 'stepper',
          'requiredValidators': ['numeric', 'optional'],
        };

        final symbol = FieldWidgetSymbol.fromJson(json);

        expect(symbol.fieldType, equals(FieldEnum.float));
        expect(symbol.uiElement, equals(UiElementEnum.stepper));
        expect(symbol.requiredValidators, equals([ValidatorType.numeric, ValidatorType.optional]));
      });

      test('should handle round-trip serialization', () {
        final original = FieldWidgetSymbol(
          fieldType: FieldEnum.enumerated,
          uiElement: UiElementEnum.dropdown,
          requiredValidators: const [ValidatorType.enumerated],
        );

        final json = original.toJson();
        final deserialized = FieldWidgetSymbol.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('Factory Constructors', () {
      test('numericSlider should create correct symbol for integer', () {
        final symbol = FieldWidgetSymbol.numericSlider();

        expect(symbol.fieldType, equals(FieldEnum.integer));
        expect(symbol.uiElement, equals(UiElementEnum.slider));
        expect(symbol.requiredValidators, equals([ValidatorType.numeric]));
      });

      test('numericSlider should create correct symbol for float', () {
        final symbol = FieldWidgetSymbol.numericSlider(fieldType: FieldEnum.float);

        expect(symbol.fieldType, equals(FieldEnum.float));
        expect(symbol.uiElement, equals(UiElementEnum.slider));
        expect(symbol.requiredValidators, equals([ValidatorType.numeric]));
      });

      test('numericStepper should create correct symbol', () {
        final symbol = FieldWidgetSymbol.numericStepper(fieldType: FieldEnum.float);

        expect(symbol.fieldType, equals(FieldEnum.float));
        expect(symbol.uiElement, equals(UiElementEnum.stepper));
        expect(symbol.requiredValidators, equals([ValidatorType.numeric]));
      });

      test('enumeratedDropdown should create correct symbol', () {
        final symbol = FieldWidgetSymbol.enumeratedDropdown();

        expect(symbol.fieldType, equals(FieldEnum.enumerated));
        expect(symbol.uiElement, equals(UiElementEnum.dropdown));
        expect(symbol.requiredValidators, equals([ValidatorType.enumerated]));
      });

      test('enumeratedRadio should create correct symbol', () {
        final symbol = FieldWidgetSymbol.enumeratedRadio();

        expect(symbol.fieldType, equals(FieldEnum.enumerated));
        expect(symbol.uiElement, equals(UiElementEnum.radio));
        expect(symbol.requiredValidators, equals([ValidatorType.enumerated]));
      });

      test('enumeratedChips should create correct symbol', () {
        final symbol = FieldWidgetSymbol.enumeratedChips();

        expect(symbol.fieldType, equals(FieldEnum.enumerated));
        expect(symbol.uiElement, equals(UiElementEnum.chips));
        expect(symbol.requiredValidators, equals([ValidatorType.enumerated]));
      });

      test('textField should create correct symbol', () {
        final symbol = FieldWidgetSymbol.textField();

        expect(symbol.fieldType, equals(FieldEnum.text));
        expect(symbol.uiElement, equals(UiElementEnum.textField));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('textArea should create correct symbol', () {
        final symbol = FieldWidgetSymbol.textArea();

        expect(symbol.fieldType, equals(FieldEnum.text));
        expect(symbol.uiElement, equals(UiElementEnum.textArea));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('booleanToggle should create correct symbol', () {
        final symbol = FieldWidgetSymbol.booleanToggle();

        expect(symbol.fieldType, equals(FieldEnum.boolean));
        expect(symbol.uiElement, equals(UiElementEnum.toggleSwitch));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('booleanCheckbox should create correct symbol', () {
        final symbol = FieldWidgetSymbol.booleanCheckbox();

        expect(symbol.fieldType, equals(FieldEnum.boolean));
        expect(symbol.uiElement, equals(UiElementEnum.checkbox));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('datePicker should create correct symbol', () {
        final symbol = FieldWidgetSymbol.datePicker();

        expect(symbol.fieldType, equals(FieldEnum.datetime));
        expect(symbol.uiElement, equals(UiElementEnum.datePicker));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('timePicker should create correct symbol', () {
        final symbol = FieldWidgetSymbol.timePicker();

        expect(symbol.fieldType, equals(FieldEnum.datetime));
        expect(symbol.uiElement, equals(UiElementEnum.timePicker));
        expect(symbol.requiredValidators, isEmpty);
      });

      test('dimensionField should create correct symbol with default UI', () {
        final symbol = FieldWidgetSymbol.dimensionField();

        expect(symbol.fieldType, equals(FieldEnum.dimension));
        expect(symbol.uiElement, equals(UiElementEnum.textField));
        expect(symbol.requiredValidators, equals([ValidatorType.dimension]));
      });

      test('dimensionField should create correct symbol with slider UI', () {
        final symbol = FieldWidgetSymbol.dimensionField(uiElement: UiElementEnum.slider);

        expect(symbol.fieldType, equals(FieldEnum.dimension));
        expect(symbol.uiElement, equals(UiElementEnum.slider));
        expect(symbol.requiredValidators, equals([ValidatorType.numeric, ValidatorType.dimension]));
      });

      test('referenceField should create correct symbol with default UI', () {
        final symbol = FieldWidgetSymbol.referenceField();

        expect(symbol.fieldType, equals(FieldEnum.reference));
        expect(symbol.uiElement, equals(UiElementEnum.dropdown));
        expect(symbol.requiredValidators, equals([ValidatorType.enumerated, ValidatorType.reference]));
      });

      test('referenceField should create correct symbol with textField UI', () {
        final symbol = FieldWidgetSymbol.referenceField(uiElement: UiElementEnum.textField);

        expect(symbol.fieldType, equals(FieldEnum.reference));
        expect(symbol.uiElement, equals(UiElementEnum.textField));
        expect(symbol.requiredValidators, equals([ValidatorType.reference]));
      });
    });

    group('Factory Constructor Assertions', () {
      test('numericSlider should assert on invalid field types', () {
        expect(
          () => FieldWidgetSymbol.numericSlider(fieldType: FieldEnum.text),
          throwsA(isA<AssertionError>()),
        );
      });

      test('numericStepper should assert on invalid field types', () {
        expect(
          () => FieldWidgetSymbol.numericStepper(fieldType: FieldEnum.boolean),
          throwsA(isA<AssertionError>()),
        );
      });

      test('dimensionField should assert on invalid UI elements', () {
        expect(
          () => FieldWidgetSymbol.dimensionField(uiElement: UiElementEnum.checkbox),
          throwsA(isA<AssertionError>()),
        );
      });

      test('referenceField should assert on invalid UI elements', () {
        expect(
          () => FieldWidgetSymbol.referenceField(uiElement: UiElementEnum.slider),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}