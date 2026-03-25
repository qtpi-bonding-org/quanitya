import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

/// Simple data class for a recognized text line with bounding box.
class OcrLine {
  final String text;
  final Rect bounds;
  const OcrLine({required this.text, required this.bounds});
}

/// Handles on-device OCR via Google ML Kit.
@lazySingleton
class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Runs OCR on an image and returns spatially-reconstructed text.
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final lines = <OcrLine>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        lines.add(OcrLine(text: line.text, bounds: line.boundingBox));
      }
    }

    final result = reconstructRows(lines);
    debugPrint('=== OCR: ${recognized.text.length} chars, '
        '${lines.length} lines, reconstructed ${result.split('\n').length} rows ===');
    return result;
  }

  /// Reconstructs text rows by grouping lines that share similar Y positions.
  /// Public and static for testability.
  static String reconstructRows(List<OcrLine> lines) {
    if (lines.isEmpty) return '';

    final heights = lines.map((l) => l.bounds.height).toList()..sort();
    final medianHeight = heights[heights.length ~/ 2];
    final yThreshold = medianHeight * 0.5;

    final sorted = List.of(lines)
      ..sort((a, b) => a.bounds.center.dy.compareTo(b.bounds.center.dy));

    final rows = <List<OcrLine>>[];
    var currentRow = <OcrLine>[sorted.first];
    var rowCenterY = sorted.first.bounds.center.dy;

    for (var i = 1; i < sorted.length; i++) {
      final line = sorted[i];
      final centerY = line.bounds.center.dy;

      if ((centerY - rowCenterY).abs() <= yThreshold) {
        currentRow.add(line);
        rowCenterY = currentRow
                .map((l) => l.bounds.center.dy)
                .reduce((a, b) => a + b) /
            currentRow.length;
      } else {
        rows.add(currentRow);
        currentRow = [line];
        rowCenterY = centerY;
      }
    }
    rows.add(currentRow);

    final buffer = StringBuffer();
    for (final row in rows) {
      row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
      buffer.writeln(row.map((l) => l.text).join('\t'));
    }

    return buffer.toString().trimRight();
  }

  @disposeMethod
  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
