import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/field_validator.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/field_validators.dart';

void main() {
  group('FieldValidators', () {
    group('required', () {
      test('returns error for null value', () {
        final validator = FieldValidators.required('Name');
        expect(validator(null), 'Name is required');
      });

      test('returns error for empty string', () {
        final validator = FieldValidators.required('Name');
        expect(validator(''), 'Name is required');
      });

      test('returns null for valid value', () {
        final validator = FieldValidators.required('Name');
        expect(validator('John'), isNull);
      });
    });

    group('numeric', () {
      test('returns error for non-numeric value', () {
        final validator = FieldValidators.numeric(label: 'Age');
        expect(validator('abc'), 'Age must be a number');
      });

      test('returns error when below min', () {
        final validator = FieldValidators.numeric(min: 0, label: 'Age');
        expect(validator(-5), 'Age must be at least 0');
      });

      test('returns error when above max', () {
        final validator = FieldValidators.numeric(max: 100, label: 'Age');
        expect(validator(150), 'Age must be at most 100');
      });

      test('returns null for valid value in range', () {
        final validator = FieldValidators.numeric(min: 0, max: 100, label: 'Age');
        expect(validator(50), isNull);
      });

      test('returns null for null value (let required handle it)', () {
        final validator = FieldValidators.numeric(min: 0, label: 'Age');
        expect(validator(null), isNull);
      });

      test('rejects decimals when allowDecimals is false', () {
        final validator = FieldValidators.numeric(
          allowDecimals: false,
          label: 'Count',
        );
        expect(validator(5.5), 'Count must be a whole number');
      });
    });

    group('text', () {
      test('returns error for non-string value', () {
        final validator = FieldValidators.text(label: 'Name');
        expect(validator(123), 'Name must be text');
      });

      test('returns error when below minLength', () {
        final validator = FieldValidators.text(minLength: 3, label: 'Name');
        expect(validator('ab'), 'Name must be at least 3 characters');
      });

      test('returns error when above maxLength', () {
        final validator = FieldValidators.text(maxLength: 5, label: 'Name');
        expect(validator('abcdef'), 'Name must be at most 5 characters');
      });

      test('returns error when pattern does not match', () {
        final validator = FieldValidators.text(
          pattern: r'^[a-z]+$',
          label: 'Code',
        );
        expect(validator('ABC123'), 'Code has invalid format');
      });

      test('returns null for valid value', () {
        final validator = FieldValidators.text(
          minLength: 2,
          maxLength: 10,
          label: 'Name',
        );
        expect(validator('John'), isNull);
      });
    });

    group('enumerated', () {
      test('returns error for invalid option', () {
        final validator = FieldValidators.enumerated(
          options: ['red', 'green', 'blue'],
          label: 'Color',
        );
        expect(validator('yellow'), 'Color must be one of: red, green, blue');
      });

      test('returns null for valid option', () {
        final validator = FieldValidators.enumerated(
          options: ['red', 'green', 'blue'],
          label: 'Color',
        );
        expect(validator('green'), isNull);
      });
    });

    group('compose', () {
      test('returns first error from multiple validators', () {
        final validator = FieldValidators.compose([
          FieldValidators.required('Value'),
          FieldValidators.numeric(min: 0, label: 'Value'),
        ]);
        expect(validator(null), 'Value is required');
      });

      test('returns null when all validators pass', () {
        final validator = FieldValidators.compose([
          FieldValidators.required('Value'),
          FieldValidators.numeric(min: 0, max: 100, label: 'Value'),
        ]);
        expect(validator(50), isNull);
      });

      test('checks validators in order', () {
        final validator = FieldValidators.compose([
          FieldValidators.required('Value'),
          FieldValidators.numeric(min: 10, label: 'Value'),
        ]);
        // Empty string fails required first
        expect(validator(''), 'Value is required');
      });
    });

    group('fromFieldValidators', () {
      test('builds validator from FieldValidator models', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 0, 'max': 100},
          ),
        ];

        final validator = FieldValidators.fromFieldValidators(validators, 'Score');
        expect(validator(-5), 'Score must be at least 0');
        expect(validator(50), isNull);
      });

      test('respects validatorOrder', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.numeric,
            validatorData: {'max': 50},
            validatorOrder: 1,
          ),
          FieldValidator(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 10},
            validatorOrder: 0,
          ),
        ];

        final validator = FieldValidators.fromFieldValidators(validators, 'Value');
        // min check (order 0) should run first
        expect(validator(5), 'Value must be at least 10');
      });

      test('uses customMessage when provided', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 0},
            customMessage: 'Please enter a positive number',
          ),
        ];

        final validator = FieldValidators.fromFieldValidators(validators, 'Value');
        expect(validator(-5), 'Please enter a positive number');
      });
    });

    group('forField', () {
      test('combines required check with field validators', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.numeric,
            validatorData: {'min': 0, 'max': 100},
          ),
        ];

        final validator = FieldValidators.forField(
          label: 'Score',
          validators: validators,
          isRequired: true,
        );

        expect(validator(null), 'Score is required');
        expect(validator(-5), 'Score must be at least 0');
        expect(validator(50), isNull);
      });

      test('skips required check when isRequired is false', () {
        final validator = FieldValidators.forField(
          label: 'Notes',
          validators: [],
          isRequired: false,
        );

        expect(validator(null), isNull);
        expect(validator(''), isNull);
      });
    });

    group('dimension', () {
      test('validates numeric dimension value', () {
        final validator = FieldValidators.dimension(
          minValue: 0,
          maxValue: 500,
          label: 'Weight',
        );
        expect(validator(-10), 'Weight must be at least 0');
        expect(validator(100), isNull);
      });

      test('rejects Map format — only bare num accepted', () {
        final validator = FieldValidators.dimension(
          minValue: 0,
          label: 'Weight',
        );
        expect(validator({'value': 75, 'unit': 'kg'}), isNotNull);
      });
    });

    group('custom', () {
      test('throws UnimplementedError', () {
        final validators = [
          FieldValidator(
            validatorType: ValidatorType.custom,
            validatorData: {'name': 'some_custom'},
          ),
        ];
        final validator = FieldValidators.fromFieldValidators(validators, 'Field');
        expect(() => validator('anything'), throwsA(isA<UnimplementedError>()));
      });
    });

    group('reference', () {
      test('accepts non-empty string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator('some-uuid'), isNull);
      });

      test('rejects empty string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator(''), isNotNull);
      });

      test('rejects non-string', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator(42), isNotNull);
      });

      test('allows null (let required handle it)', () {
        final validator = FieldValidators.reference(label: 'Ref');
        expect(validator(null), isNull);
      });
    });
  });
}
