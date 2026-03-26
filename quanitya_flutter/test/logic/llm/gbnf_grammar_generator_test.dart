import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/llm/services/gbnf_grammar_generator.dart';

void main() {
  group('GbnfGrammarGenerator', () {
    test('generates grammar with all values as strings', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [
          GbnfField(key: 'name', type: GbnfFieldType.string),
          GbnfField(key: 'count', type: GbnfFieldType.integer),
          GbnfField(key: 'price', type: GbnfFieldType.number),
          GbnfField(key: 'active', type: GbnfFieldType.boolean),
        ],
        asList: false,
      );

      // All keys must be JSON-quoted
      expect(grammar, contains(r'"\"name\""'));
      expect(grammar, contains(r'"\"count\""'));
      expect(grammar, contains(r'"\"price\""'));
      expect(grammar, contains(r'"\"active\""'));

      // All values use the string rule (NuExtract outputs everything as strings)
      expect(grammar, contains('string'));
      // Should NOT contain integer/number/boolean rules
      expect(grammar, isNot(contains('integer ::')));
      expect(grammar, isNot(contains('number ::')));
      expect(grammar, isNot(contains('boolean ::')));
    });

    test('generates grammar with JSON-quoted keys', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'Item Name', type: GbnfFieldType.string)],
        asList: false,
      );
      expect(grammar, contains('root'));
      expect(grammar, contains(r'"\"Item Name\""'));
    });

    test('asList=true wraps in array production', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'name', type: GbnfFieldType.string)],
        asList: true,
      );
      expect(grammar, contains('['));
      expect(grammar, contains(']'));
    });

    test('asList=false produces single object', () {
      final grammarList = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'name', type: GbnfFieldType.string)],
        asList: true,
      );
      final grammarSingle = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'name', type: GbnfFieldType.string)],
        asList: false,
      );
      expect(grammarList, isNot(equals(grammarSingle)));
    });

    test('throws on empty fields', () {
      expect(
        () => GbnfGrammarGenerator.generate(fields: []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
