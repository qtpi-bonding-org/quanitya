import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('font debug', (tester) async {
    // Load static font directly
    final file = File('test/screenshots/fonts/AtkinsonHyperlegibleMono-Regular.ttf');
    final loader = FontLoader('Atkinson Hyperlegible Mono');
    loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    await loader.load();

    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Default font: Hello World', style: TextStyle(fontSize: 24)),
                Text('Atkinson: Hello World', style: TextStyle(fontFamily: 'Atkinson Hyperlegible Mono', fontSize: 24)),
                Text('Atkinson numbers: 12345', style: TextStyle(fontFamily: 'Atkinson Hyperlegible Mono', fontSize: 24)),
                const Text('Default numbers: 12345', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/font_debug.png'),
    );
  });
}
