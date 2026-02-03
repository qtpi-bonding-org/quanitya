import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generate a repeatable zen background tile for use as a web asset
/// 
/// This creates a single tile that can be repeated seamlessly.
/// Run with: flutter test --update-goldens test/generate_zen_background_test.dart
void main() {
  group('Zen Background Generation', () {
    testWidgets('Generate Zen Background Tile - 240x240px', (WidgetTester tester) async {
      // Set the size to 10 grid units (24px * 10 = 240px)
      // This creates a perfect repeatable tile
      const tileSize = 240.0;
      tester.view.physicalSize = const Size(tileSize, tileSize);
      tester.view.devicePixelRatio = 1.0;

      // Build the zen background widget
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            color: const Color(0xFFFAF7F0),
            child: CustomPaint(
              key: const Key('zen_background'),
              painter: ZenBackgroundPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      // Save as golden file
      await expectLater(
        find.byKey(const Key('zen_background')),
        matchesGoldenFile('goldens/zen_background_tile_240.png'),
      );
    });

    testWidgets('Generate Zen Background Tile - 480x480px (2x)', (WidgetTester tester) async {
      // Larger tile for higher resolution displays
      const tileSize = 480.0;
      tester.view.physicalSize = const Size(tileSize, tileSize);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            color: const Color(0xFFFAF7F0),
            child: CustomPaint(
              key: const Key('zen_background_480'),
              painter: ZenBackgroundPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(const Key('zen_background_480')),
        matchesGoldenFile('goldens/zen_background_tile_480.png'),
      );
    });

    testWidgets('Generate Zen Background Full HD - 1920x1080px', (WidgetTester tester) async {
      // Full HD version for hero sections
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            color: const Color(0xFFFAF7F0),
            child: CustomPaint(
              key: const Key('zen_background_1080p'),
              painter: ZenBackgroundPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(const Key('zen_background_1080p')),
        matchesGoldenFile('goldens/zen_background_1920x1080.png'),
      );
    });
  }, skip: 'Skipping golden generation tests in CI/Test env');
}

/// Custom painter that replicates the zen paper background
class ZenBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Zen paper colors (from QuanityaPalette)
    const washiWhite = Color(0xFFFAF7F0);
    const blueGrey = Color(0xFF4D5B60);
    
    // Zen grid constants
    const dotSpacing = 24.0;
    const dotRadius = 1.2;
    const dotOpacity = 0.25;

    // 1. Fill base color
    final bgPaint = Paint()..color = washiWhite;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw dot grid pattern
    final dotPaint = Paint()
      ..color = blueGrey.withOpacity(dotOpacity)
      ..style = PaintingStyle.fill;

    // Calculate horizontal offset to center the grid
    final horizontalOffset = (size.width % dotSpacing) / 2;
    
    // For a repeatable tile, we want dots to start at edges
    // So we use 0 as the starting point
    const startX = 0.0;
    const startY = 0.0;

    // Draw dots in a regular grid
    for (double x = startX; x < size.width; x += dotSpacing) {
      for (double y = startY; y < size.height; y += dotSpacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotRadius,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
