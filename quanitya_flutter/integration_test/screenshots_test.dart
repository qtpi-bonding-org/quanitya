/// Store screenshot automation.
///
/// Boots the real app, seeds data via dev tools, navigates to each
/// screen, and captures screenshots.
///
/// Run:
///   flutter test integration_test/screenshots_test.dart -d <device_id>
///
/// Example with iPhone 16 Pro Max simulator:
///   xcrun simctl boot "iPhone 16 Pro Max"
///   flutter test integration_test/screenshots_test.dart -d 5EFA224F-52F1-489E-97B8-8BD29E60D273
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:quanitya_flutter/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Output directory for screenshots
  const outputDir = 'screenshots';

  /// Helper to take a screenshot and save to disk.
  Future<void> takeScreenshot(String name) async {
    // On iOS/Android, use binding.takeScreenshot
    // On macOS/desktop, fall back to binding.convertFlutterSurfaceToImage
    final bytes = await binding.takeScreenshot(name);
    final dir = Directory(outputDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('$outputDir/$name.png');
    file.writeAsBytesSync(bytes);
    debugPrint('Screenshot saved: ${file.path}');
  }

  group('Store Screenshots', () {
    testWidgets('capture all screens', (tester) async {
      // Boot the real app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // ── 1. Temporal Present (default landing page) ──────────────
      await takeScreenshot('01_temporal_present');

      // ── 2. Temporal Past ────────────────────────────────────────
      // Tap the '-t' label
      final pastTab = find.text('-t');
      if (pastTab.evaluate().isNotEmpty) {
        await tester.tap(pastTab);
        await tester.pumpAndSettle();
      }
      await takeScreenshot('02_temporal_past');

      // ── 3. Temporal Future ──────────────────────────────────────
      // Go back to present first, then to future
      final presentTab = find.text('t');
      if (presentTab.evaluate().isNotEmpty) {
        await tester.tap(presentTab.first);
        await tester.pumpAndSettle();
      }
      final futureTab = find.text('+t');
      if (futureTab.evaluate().isNotEmpty) {
        await tester.tap(futureTab);
        await tester.pumpAndSettle();
      }
      await takeScreenshot('03_temporal_future');

      // Return to present for remaining navigation
      if (presentTab.evaluate().isNotEmpty) {
        await tester.tap(presentTab.first);
        await tester.pumpAndSettle();
      }

      // ── Remaining screenshots need manual seed first ────────────
      // The app starts without seeded data unless the dev FAB is tapped.
      // For now, capture what's available.
      // TODO: Automate dev seeder trigger or pre-seed before app boot.
    });
  });
}
