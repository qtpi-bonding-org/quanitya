/// Value types supported in GBNF grammar generation.
enum GbnfFieldType { string, integer, number, boolean, enumerated }

/// A field definition for GBNF grammar generation.
///
/// Generic — not template-aware. Used by [GbnfGrammarGenerator] to
/// produce grammars that constrain LLM output to a specific JSON shape.
class GbnfField {
  final String key;
  final GbnfFieldType type;

  /// Required when [type] is [GbnfFieldType.enumerated].
  /// The grammar will constrain output to exactly these values.
  final List<String>? enumValues;

  const GbnfField({
    required this.key,
    required this.type,
    this.enumValues,
  });
}
