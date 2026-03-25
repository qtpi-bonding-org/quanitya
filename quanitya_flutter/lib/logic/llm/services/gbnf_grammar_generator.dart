import '../models/gbnf_field.dart';

/// Generates GBNF grammars that constrain LLM output to a specific JSON shape.
///
/// Pure static utility — no state, no dependencies.
///
/// GBNF (GGML BNF) is the grammar format used by llama.cpp to constrain
/// token generation. This generator produces grammars that force the model
/// to output JSON objects with specific field names and value types.
class GbnfGrammarGenerator {
  GbnfGrammarGenerator._();

  /// Generates a GBNF grammar from field definitions.
  ///
  /// [fields] defines the keys and value types for the JSON object.
  /// [asList] if true, root produces a JSON array of objects.
  ///
  /// Throws [ArgumentError] if fields is empty or if an enumerated
  /// field has null/empty enumValues.
  static String generate({
    required List<GbnfField> fields,
    bool asList = true,
  }) {
    if (fields.isEmpty) {
      throw ArgumentError('fields must not be empty');
    }

    for (final field in fields) {
      if (field.type == GbnfFieldType.enumerated) {
        if (field.enumValues == null || field.enumValues!.isEmpty) {
          throw ArgumentError(
            'Enumerated field "${field.key}" must have non-empty enumValues',
          );
        }
      }
    }

    final buf = StringBuffer();

    // Root rule
    if (asList) {
      buf.writeln('root ::= "[" ws object ("," ws object)* "]" ws');
    } else {
      buf.writeln('root ::= object');
    }
    buf.writeln();

    // Object rule — fixed keys in order
    buf.write('object ::= "{" ws ');
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final escapedKey = _escapeGbnfString(field.key);
      final valueRule = _valueRuleName(i, field);

      if (i > 0) buf.write(' "," ws ');
      buf.write('"$escapedKey" ":" ws $valueRule');
    }
    buf.writeln(' "}" ws');
    buf.writeln();

    // Value type rules (deduplicated by a sentinel set)
    final emittedPrimitives = <String>{};

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final ruleName = _valueRuleName(i, field);

      switch (field.type) {
        case GbnfFieldType.string:
          if (!emittedPrimitives.contains('string')) {
            emittedPrimitives.add('string');
            buf.writeln(
              r'string ::= "\"" ([^\\\"\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F]{4}))* "\"" ws',
            );
          }
        case GbnfFieldType.integer:
          if (!emittedPrimitives.contains('integer')) {
            emittedPrimitives.add('integer');
            buf.writeln('integer ::= ("-"? ([0-9] | [1-9] [0-9]*)) ws');
          }
        case GbnfFieldType.number:
          if (!emittedPrimitives.contains('number')) {
            emittedPrimitives.add('number');
            buf.writeln(
              'number ::= ("-"? ([0-9] | [1-9] [0-9]*)) ("." [0-9]+)? ws',
            );
          }
        case GbnfFieldType.boolean:
          if (!emittedPrimitives.contains('boolean')) {
            emittedPrimitives.add('boolean');
            buf.writeln('boolean ::= ("true" | "false") ws');
          }
        case GbnfFieldType.enumerated:
          // Each enumerated field gets its own named rule.
          // Values are wrapped in escaped quotes so the LLM outputs
          // JSON-valid quoted strings, e.g.:
          //   enum_0 ::= ("\"food\"" | "\"drink\"" | "\"snack\"") ws
          //   → LLM outputs: "food" or "drink" or "snack" (with quotes)
          final values = field.enumValues!
              .map((v) => '"\\\"${_escapeGbnfString(v)}\\\""')
              .join(' | ');
          buf.writeln('$ruleName ::= ($values) ws');
      }
    }

    buf.writeln();
    buf.writeln('ws ::= ([ \\t\\n] ws)?');

    return buf.toString();
  }

  static String _valueRuleName(int index, GbnfField field) {
    return switch (field.type) {
      GbnfFieldType.string => 'string',
      GbnfFieldType.integer => 'integer',
      GbnfFieldType.number => 'number',
      GbnfFieldType.boolean => 'boolean',
      GbnfFieldType.enumerated => 'enum_$index',
    };
  }

  static String _escapeGbnfString(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
