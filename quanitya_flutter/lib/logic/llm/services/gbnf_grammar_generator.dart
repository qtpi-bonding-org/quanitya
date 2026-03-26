import '../models/gbnf_field.dart';

/// Generates GBNF grammars that constrain LLM output to a specific JSON shape.
///
/// Pure static utility — no state, no dependencies.
///
/// GBNF (GGML BNF) is the grammar format used by llama.cpp to constrain
/// token generation. This generator produces grammars that force the model
/// to output JSON objects with specific field names and string values.
///
/// NuExtract outputs everything as strings, so ALL values are constrained
/// to JSON strings. Enumerated fields are further constrained to their
/// allowed values. Type coercion happens after extraction.
class GbnfGrammarGenerator {
  GbnfGrammarGenerator._();

  /// Generates a GBNF grammar from field definitions.
  ///
  /// All values are emitted as JSON strings matching NuExtract's training
  /// format. Enumerated fields are constrained to their allowed values.
  /// Type coercion is done post-extraction.
  ///
  /// [fields] defines the keys for the JSON object.
  /// [asList] if true, root produces a JSON array of objects.
  ///
  /// Throws [ArgumentError] if fields is empty.
  static String generate({
    required List<GbnfField> fields,
    bool asList = true,
  }) {
    if (fields.isEmpty) {
      throw ArgumentError('fields must not be empty');
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
      buf.write('"\\\"$escapedKey\\\"" ":" ws $valueRule');
    }
    buf.writeln(' "}" ws');
    buf.writeln();

    // Value rules
    final needsGenericString = fields.any((f) =>
        f.type != GbnfFieldType.enumerated ||
        f.enumValues == null ||
        f.enumValues!.isEmpty);

    if (needsGenericString) {
      buf.writeln(
        r'string ::= "\"" ([^\\\"\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F]{4}))* "\"" ws',
      );
    }

    // Enum-specific rules: constrain to allowed values as JSON-quoted strings
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (field.type == GbnfFieldType.enumerated &&
          field.enumValues != null &&
          field.enumValues!.isNotEmpty) {
        final values = field.enumValues!
            .map((v) => '"\\\"${_escapeGbnfString(v)}\\\""')
            .join(' | ');
        buf.writeln('enum_$i ::= ($values) ws');
      }
    }

    buf.writeln();
    buf.writeln('ws ::= ([ \\t\\n] ws)?');

    return buf.toString();
  }

  /// Returns the GBNF rule name for a field's value.
  ///
  /// Enumerated fields with values get a dedicated rule constraining
  /// output to allowed values. Everything else uses the generic string rule.
  static String _valueRuleName(int index, GbnfField field) {
    if (field.type == GbnfFieldType.enumerated &&
        field.enumValues != null &&
        field.enumValues!.isNotEmpty) {
      return 'enum_$index';
    }
    return 'string';
  }

  /// Escapes a string for use as a GBNF literal.
  static String _escapeGbnfString(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
