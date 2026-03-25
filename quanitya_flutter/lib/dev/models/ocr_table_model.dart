/// Simple mutable table model for the OCR table editor.
/// Dev-only — not production code.
class OcrTableModel {
  List<List<String>> _cells;

  OcrTableModel(this._cells);

  /// Parse OCR text (newline-separated rows, tab-separated columns)
  /// into a rectangular grid padded with empty strings.
  factory OcrTableModel.fromOcrText(String ocrText) {
    if (ocrText.trim().isEmpty) return OcrTableModel([]);

    final rows = ocrText.split('\n').where((r) => r.isNotEmpty).toList();
    final parsed = rows.map((r) => r.split('\t')).toList();

    // Pad to max column count
    final maxCols = parsed.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    for (final row in parsed) {
      while (row.length < maxCols) {
        row.add('');
      }
    }

    return OcrTableModel(parsed);
  }

  int get rowCount => _cells.length;
  int get columnCount => _cells.isEmpty ? 0 : _cells.first.length;
  bool get isEmpty => _cells.isEmpty;

  String getCell(int row, int col) => _cells[row][col];

  void updateCell(int row, int col, String value) {
    _cells[row][col] = value;
  }

  void deleteRow(int index) {
    if (index >= 0 && index < _cells.length) {
      _cells.removeAt(index);
    }
  }

  void deleteColumn(int index) {
    if (_cells.isEmpty || index < 0 || index >= columnCount) return;
    for (final row in _cells) {
      row.removeAt(index);
    }
    // Remove rows that are now empty
    _cells.removeWhere((row) => row.isEmpty);
  }

  /// Reconstruct tab-separated text for the LLM.
  /// Skips rows where all cells are empty.
  String toText() {
    final buf = StringBuffer();
    for (final row in _cells) {
      final nonEmpty = row.where((c) => c.trim().isNotEmpty).toList();
      if (nonEmpty.isEmpty) continue;
      buf.writeln(row.where((c) => c.trim().isNotEmpty).join('\t'));
    }
    return buf.toString().trimRight();
  }
}
