import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/validator_data_schema.dart';

void main() {
  group('ValidatorDataSchema', () {
    group('numeric', () {
      test('accepts valid numeric config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.numeric,
          {'min': 0, 'max': 100, 'allowDecimals': true},
        );
        expect(result, isNull);
      });

      test('accepts empty config', () {
        expect(ValidatorDataSchema.validate(ValidatorType.numeric, {}), isNull);
      });

      test('rejects min as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.numeric,
          {'min': '0'},
        );
        expect(result, isNotNull);
      });
    });

    group('text', () {
      test('accepts valid text config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.text,
          {'minLength': 1, 'maxLength': 255},
        );
        expect(result, isNull);
      });

      test('rejects minLength as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.text,
          {'minLength': '1'},
        );
        expect(result, isNotNull);
      });
    });

    group('enumerated', () {
      test('accepts valid options list', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.enumerated,
          {'options': ['a', 'b', 'c']},
        );
        expect(result, isNull);
      });

      test('rejects options with non-string items', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.enumerated,
          {'options': [1, 2, 3]},
        );
        expect(result, isNotNull);
      });
    });

    group('dimension', () {
      test('accepts valid dimension config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.dimension,
          {'minValue': 0, 'maxValue': 500},
        );
        expect(result, isNull);
      });

      test('rejects minValue as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.dimension,
          {'minValue': '0'},
        );
        expect(result, isNotNull);
      });
    });

    group('list', () {
      test('accepts valid list config', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.list,
          {'minItems': 1, 'maxItems': 10},
        );
        expect(result, isNull);
      });

      test('rejects minItems as string', () {
        final result = ValidatorDataSchema.validate(
          ValidatorType.list,
          {'minItems': '1'},
        );
        expect(result, isNotNull);
      });
    });

    group('optional', () {
      test('accepts empty config', () {
        expect(
            ValidatorDataSchema.validate(ValidatorType.optional, {}), isNull);
      });
    });
  });
}
