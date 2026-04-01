@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;
import 'package:quanitya_flutter/design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'package:quanitya_flutter/features/home/pages/temporal_home_page.dart';

import 'screenshot_bootstrap.dart';

void main() {
  group('Store Screenshots', () {
    setUp(() async {
      await configureScreenshotDependencies();
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('temporal present — home screen', (tester) async {
      // iPhone dimensions at 1x pixel ratio for golden comparison
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // buildScreenshotApp provides the full MultiProvider (cubits + services
      // + mappers) mirroring app.dart, so TemporalHomePage can access
      // everything it needs via context.read/watch.
      await tester.pumpWidget(
        buildScreenshotApp(
          child: const ZenPaperBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: TemporalHomePage(),
            ),
          ),
        ),
      );

      // Let streams settle and animations complete
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/temporal_present.png'),
      );
    });
  });
}
