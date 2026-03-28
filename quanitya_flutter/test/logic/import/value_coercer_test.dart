import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/import/services/value_coercer.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';

void main() {
  group('ValueCoercer', () {
    test('coerces integer strings', () {
      expect(ValueCoercer.coerce('42', GbnfFieldType.integer), 42);
      expect(ValueCoercer.coerce('42', GbnfFieldType.integer), isA<int>());
    });

    test('coerces number strings', () {
      expect(ValueCoercer.coerce('3.14', GbnfFieldType.number), 3.14);
      expect(ValueCoercer.coerce('3.14', GbnfFieldType.number), isA<double>());
    });

    test('coerces boolean strings', () {
      expect(ValueCoercer.coerce('true', GbnfFieldType.boolean), true);
      expect(ValueCoercer.coerce('false', GbnfFieldType.boolean), false);
      expect(ValueCoercer.coerce('TRUE', GbnfFieldType.boolean), true);
    });

    test('keeps string type as-is', () {
      expect(ValueCoercer.coerce('hello', GbnfFieldType.string), 'hello');
    });

    test('strips currency prefix for numbers', () {
      expect(ValueCoercer.coerce('\$4.66', GbnfFieldType.number), 4.66);
      expect(ValueCoercer.coerce('€10.00', GbnfFieldType.number), 10.0);
    });

    test('keeps values that fail coercion as strings', () {
      expect(ValueCoercer.coerce('not-a-number', GbnfFieldType.number), 'not-a-number');
      expect(ValueCoercer.coerce('maybe', GbnfFieldType.boolean), 'maybe');
    });

    test('normalizes whitespace-only to empty string', () {
      expect(ValueCoercer.coerce('  ', GbnfFieldType.number), '');
      expect(ValueCoercer.coerce('  ', GbnfFieldType.string), '');
    });

    test('passes through non-string values unchanged', () {
      expect(ValueCoercer.coerce(42, GbnfFieldType.integer), 42);
      expect(ValueCoercer.coerce(3.14, GbnfFieldType.number), 3.14);
      expect(ValueCoercer.coerce(true, GbnfFieldType.boolean), true);
    });
  });
}
