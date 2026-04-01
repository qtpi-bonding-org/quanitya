@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;
import 'package:quanitya_flutter/design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quanitya_flutter/features/home/pages/notebook_shell.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_cubit.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart';

import 'screenshot_bootstrap.dart';

Future<void> _loadStaticFonts() async {
  const fontsDir = 'test/screenshots/fonts';
  final fonts = {
    'Atkinson Hyperlegible Mono': [
      'AtkinsonHyperlegibleMono-Light',
      'AtkinsonHyperlegibleMono-Regular',
      'AtkinsonHyperlegibleMono-Medium',
      'AtkinsonHyperlegibleMono-Bold',
      'AtkinsonHyperlegibleMono-ExtraBold',
    ],
    'Noto Sans Mono': [
      'NotoSansMono-Light',
      'NotoSansMono-Regular',
      'NotoSansMono-Medium',
      'NotoSansMono-Bold',
    ],
  };

  for (final entry in fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final name in entry.value) {
      final file = File('$fontsDir/$name.ttf');
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.view(file.readAsBytesSync().buffer)),
        );
      }
    }
    await loader.load();
  }
}

void main() {
  group('Store Screenshots', () {
    setUp(() async {
      await configureScreenshotDependencies();
      // Load static fonts directly — variable fonts don't render in test
      await _loadStaticFonts();
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgets('temporal present — home screen', (tester) async {
      // iPhone 16 Pro Max: 1320x2868 physical, 3x DPR = 440x956 logical
      tester.view.physicalSize = const Size(1320, 2868);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildScreenshotApp(
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<DataExportCubit>()),
              BlocProvider(create: (_) => getIt<RecoveryKeyCubit>()),
              BlocProvider(create: (_) => getIt<DeviceManagementCubit>()),
              BlocProvider(create: (_) => getIt<WebhookCubit>()),
              BlocProvider(create: (_) => getIt<FeedbackCubit>()),
            ],
            child: const ZenPaperBackground(
              child: NotebookShell(),
            ),
          ),
        ),
      );

      // pumpAndSettle can timeout with stream-based cubits — pump a few frames instead
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/temporal_present.png'),
      );
    });
  });
}
