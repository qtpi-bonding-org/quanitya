import 'package:csv/csv.dart';

/// Parses CSV text into header-keyed rows.
/// Pure static utility — no template knowledge.
class CsvParser {
  CsvParser._();

  static const _converter = CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  );

  /// Normalises line endings to LF so the converter works consistently.
  static String _normalise(String csvText) =>
      csvText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  /// Parses CSV text into a list of maps keyed by header names.
  /// First row is headers (trimmed). Empty rows skipped. All values are strings.
  static List<Map<String, String>> parse(String csvText) {
    if (csvText.trim().isEmpty) return [];
    final rows = _converter.convert(_normalise(csvText));
    if (rows.length < 2) return [];
    final headers = rows.first.map((h) => h.toString().trim()).toList();
    if (headers.isEmpty) return [];

    final result = <Map<String, String>>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row.first.toString().trim().isEmpty)) continue;
      final map = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        map[headers[j]] = j < row.length ? row[j].toString() : '';
      }
      result.add(map);
    }
    return result;
  }

  /// Extracts just the header names from CSV text.
  static List<String> extractHeaders(String csvText) {
    if (csvText.trim().isEmpty) return [];
    final rows = _converter.convert(_normalise(csvText));
    if (rows.isEmpty) return [];
    return rows.first.map((h) => h.toString().trim()).toList();
  }
}
