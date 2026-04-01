import 'dart:async';

import 'package:flutter_test_goldens/flutter_test_goldens.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await TestFonts.loadAppFonts();
  await loadMaterialIconsFont();
  return testMain();
}
