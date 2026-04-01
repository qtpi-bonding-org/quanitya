import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  return testMain();
}
