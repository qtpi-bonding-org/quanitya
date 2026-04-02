import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test_goldens/flutter_test_goldens.dart';

/// Loads static font files for golden tests.
///
/// Flutter's test renderer can't handle variable fonts (renders as Ahem
/// black rectangles). Static .ttf files per weight work correctly.
Future<void> _loadStaticFonts() async {
  final fontsDir = 'test/screenshots/fonts';

  // Atkinson Hyperlegible Mono — header font
  final atkinsonLoader = FontLoader('Atkinson Hyperlegible Mono');
  for (final weight in ['Light', 'Regular', 'Medium', 'Bold', 'ExtraBold']) {
    final file = File('$fontsDir/AtkinsonHyperlegibleMono-$weight.ttf');
    if (file.existsSync()) {
      atkinsonLoader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await atkinsonLoader.load();

  // Noto Sans Mono — body font
  final notoLoader = FontLoader('Noto Sans Mono');
  for (final weight in ['Light', 'Regular', 'Medium', 'Bold']) {
    final file = File('$fontsDir/NotoSansMono-$weight.ttf');
    if (file.existsSync()) {
      notoLoader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await notoLoader.load();
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadStaticFonts();
  await loadMaterialIconsFont();
  await initializeDateFormatting();

  // Allow small pixel diffs (< 0.5%) — the home screen clock causes
  // time-dependent rendering that shifts a few pixels between runs.
  if (goldenFileComparator is LocalFileComparator) {
    final basedir = (goldenFileComparator as LocalFileComparator).basedir;
    // LocalFileComparator expects a file URI; it derives basedir by going up one level.
    // Create a dummy file URI in the test directory so basedir resolves correctly.
    final testFileUri = basedir.resolve('store_screenshots_test.dart');
    goldenFileComparator = _TolerantFileComparator(testFileUri);
  }

  return testMain();
}

/// Comparator that tolerates small pixel differences from dynamic content
/// (e.g., real-time clock on the home screen).
class _TolerantFileComparator extends LocalFileComparator {
  _TolerantFileComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    // Allow up to 0.5% pixel difference
    if (!result.passed && result.diffPercent <= 0.5) {
      return true;
    }
    return result.passed;
  }
}
