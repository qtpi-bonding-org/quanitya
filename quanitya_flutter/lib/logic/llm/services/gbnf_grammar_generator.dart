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
/// to JSON strings. Type coercion happens after extraction.
class GbnfGrammarGenerator {
  GbnfGrammarGenerator._();

  /// Generates a GBNF grammar from field definitions.
  ///
  /// All values are emitted as JSON strings regardless of [GbnfFieldType],
  /// matching NuExtract's training format. Type coercion is done post-extraction.
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

    // Object rule — fixed keys in order, all values are strings
    buf.write('object ::= "{" ws ');
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      final escapedKey = _escapeGbnfString(field.key);

      if (i > 0) buf.write(' "," ws ');
      buf.write('"\\\"$escapedKey\\\"" ":" ws string');
    }
    buf.writeln(' "}" ws');
    buf.writeln();

    // String value rule — all values are JSON strings
    buf.writeln(
      r'string ::= "\"" ([^\\\"\x7F\x00-\x1F] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F]{4}))* "\"" ws',
    );

    buf.writeln();
    buf.writeln('ws ::= ([ \\t\\n] ws)?');

    return buf.toString();
  }

  /// Escapes a string for use as a GBNF literal.
  static String _escapeGbnfString(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
