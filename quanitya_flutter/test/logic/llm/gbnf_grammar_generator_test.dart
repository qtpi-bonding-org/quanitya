import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/llm/services/gbnf_grammar_generator.dart';

void main() {
  group('GbnfGrammarGenerator', () {
    test('generates all-string grammar with JSON-quoted keys', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [
          GbnfField(key: 'Item Name', type: GbnfFieldType.string),
          GbnfField(key: 'Price', type: GbnfFieldType.number),
          GbnfField(key: 'Count', type: GbnfFieldType.integer),
          GbnfField(key: 'Active', type: GbnfFieldType.boolean),
        ],
        asList: false,
      );
      expect(grammar, contains('root'));
      expect(grammar, contains(r'"\"Item Name\""'));
      expect(grammar, contains(r'"\"Price\""'));
      expect(grammar, contains('string'));
      expect(grammar, isNot(contains('integer ::')));
      expect(grammar, isNot(contains('number ::')));
      expect(grammar, isNot(contains('boolean ::')));
    });

    test('asList wraps in array production', () {
      final list = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'x', type: GbnfFieldType.string)],
        asList: true,
      );
      final single = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'x', type: GbnfFieldType.string)],
        asList: false,
      );
      expect(list, contains('"[" ws object'));
      expect(single, isNot(contains('"["')));
    });

    test('throws on empty fields', () {
      expect(
        () => GbnfGrammarGenerator.generate(fields: []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
