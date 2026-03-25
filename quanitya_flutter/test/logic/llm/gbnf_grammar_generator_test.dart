import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/llm/services/gbnf_grammar_generator.dart';

void main() {
  group('GbnfGrammarGenerator', () {
    test('generates grammar with string field', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'name', type: GbnfFieldType.string)],
        asList: false,
      );
      expect(grammar, contains('root'));
      expect(grammar, contains('"name"'));
      expect(grammar, contains('string'));
    });

    test('generates grammar with integer field', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'count', type: GbnfFieldType.integer)],
        asList: false,
      );
      expect(grammar, contains('"count"'));
      expect(grammar, contains('integer'));
    });

    test('generates grammar with number (float) field', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'price', type: GbnfFieldType.number)],
        asList: false,
      );
      expect(grammar, contains('"price"'));
      expect(grammar, contains('number'));
    });

    test('generates grammar with boolean field', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [GbnfField(key: 'organic', type: GbnfFieldType.boolean)],
        asList: false,
      );
      expect(grammar, contains('"organic"'));
      expect(grammar, contains('"true"'));
      expect(grammar, contains('"false"'));
    });

    test('generates grammar with enumerated field', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [
          GbnfField(
            key: 'category',
            type: GbnfFieldType.enumerated,
            enumValues: ['food', 'drink', 'snack'],
          ),
        ],
        asList: false,
      );
      expect(grammar, contains('"category"'));
      expect(grammar, contains('"food"'));
      expect(grammar, contains('"drink"'));
      expect(grammar, contains('"snack"'));
    });

    test('generates grammar with multiple fields', () {
      final grammar = GbnfGrammarGenerator.generate(
        fields: [
          GbnfField(key: 'Item Name', type: GbnfFieldType.string),
          GbnfField(key: 'Price', type: GbnfFieldType.number),
          GbnfField(key: 'Quantity', type: GbnfFieldType.integer),
        ],
        asList: false,
      );
      expect(grammar, contains('"Item Name"'));
      expect(grammar, contains('"Price"'));
      expect(grammar, contains('"Quantity"'));
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
      expect(grammarList, contains('"name"'));
      expect(grammarSingle, contains('"name"'));
      expect(grammarList, isNot(equals(grammarSingle)));
    });

    test('throws on enumerated field with no enumValues', () {
      expect(
        () => GbnfGrammarGenerator.generate(
          fields: [GbnfField(key: 'bad', type: GbnfFieldType.enumerated)],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on empty fields', () {
      expect(
        () => GbnfGrammarGenerator.generate(fields: []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
