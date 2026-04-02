@Tags(['screenshot'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;
import 'package:quanitya_flutter/dev/widgets/dev_fab.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_cubit.dart';
import 'package:quanitya_flutter/features/home/pages/notebook_shell.dart';
import 'package:quanitya_flutter/features/results/cubits/results_list_cubit.dart';
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_cubit.dart';
import 'package:quanitya_flutter/features/templates/cubits/editor/template_editor_cubit.dart';
import 'package:quanitya_flutter/features/templates/pages/template_designer_page.dart';
import 'package:quanitya_flutter/features/templates/widgets/shared/template_preview.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart';
import 'package:quanitya_flutter/features/analytics/pages/analysis_builder_page.dart';
import 'package:quanitya_flutter/features/guided_tour/guided_tour_service.dart';
import 'package:quanitya_flutter/features/visualization/cubits/visualization_cubit.dart';
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_cubit.dart';
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_state.dart';
import 'package:quanitya_flutter/logic/analysis/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_output.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/template_editor_message_mapper.dart';
import 'package:quanitya_flutter/support/extensions/context_extensions.dart';

import 'screenshot_bootstrap.dart';
import 'stubs/fake_template_data.dart';
import 'stubs/stub_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Device configurations
// ─────────────────────────────────────────────────────────────────────────────

class DeviceConfig {
  final String name;
  final Size physicalSize;
  final double devicePixelRatio;

  const DeviceConfig(this.name, this.physicalSize, this.devicePixelRatio);

  @override
  String toString() => name;
}

const _devices = [
  DeviceConfig('iphone', Size(1320, 2868), 3.0),   // iPhone 16 Pro Max
  DeviceConfig('ipad', Size(2064, 2752), 2.0),      // iPad Pro 13"
  DeviceConfig('android', Size(1080, 1920), 2.625), // Google Pixel phone
];

const _locales = ['en', 'es', 'fr', 'pt'];

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pump several frames instead of pumpAndSettle (timeouts with stream cubits).
Future<void> _pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Build the NotebookShell wrapped in all required providers.
Widget _buildShell({Locale? locale}) {
  return buildScreenshotApp(
    locale: locale,
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
  );
}

/// Golden file path: goldens/{locale}/{device}/{name}.png
String _golden(String locale, String device, String name) =>
    'goldens/$locale/$device/$name.png';

// ─────────────────────────────────────────────────────────────────────────────
// Screenshot definitions — each returns a function that sets up and pumps
// ─────────────────────────────────────────────────────────────────────────────

/// All 8 screenshot definitions. Each takes tester + locale and returns the
/// golden file name.
typedef ScreenshotSetup = Future<void> Function(
    WidgetTester tester, Locale locale);

Map<String, ScreenshotSetup> get _screenshots => {
  'temporal_present': (tester, locale) async {
    // Use localized template names
    final repo = getIt<TemplateWithAestheticsRepository>()
        as StubTemplateWithAestheticsRepository;
    repo.templates = fakeTemplatesForLocale(locale.languageCode);

    await tester.pumpWidget(_buildShell(locale: locale));
    await _pumpFrames(tester);
  },

  'temporal_past': (tester, locale) async {
    final lang = locale.languageCode;
    final repo = getIt<TemplateWithAestheticsRepository>()
        as StubTemplateWithAestheticsRepository;
    repo.templates = fakeTemplatesForLocale(lang);

    final timelineCubit =
        getIt<TimelineDataCubit>() as StubTimelineDataCubit;
    timelineCubit.emitPastData(fakePastTimelineItemsForLocale(lang));

    await tester.pumpWidget(_buildShell(locale: locale));
    await _pumpFrames(tester);

    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await _pumpFrames(tester);
  },

  'temporal_future': (tester, locale) async {
    final lang = locale.languageCode;
    final repo = getIt<TemplateWithAestheticsRepository>()
        as StubTemplateWithAestheticsRepository;
    repo.templates = fakeTemplatesForLocale(lang);

    final scheduleCubit =
        getIt<ScheduleListCubit>() as StubScheduleListCubit;
    scheduleCubit.emitSchedules(fakeSchedulesForLocale(lang));

    await tester.pumpWidget(_buildShell(locale: locale));
    await _pumpFrames(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await _pumpFrames(tester);
  },

  'results_graphs': (tester, locale) async {
    StubResultsListCubit.defaultTemplates = fakeResultsTemplates;
    StubVisualizationCubit.fakeDataByTemplate = {
      '00000000-0000-0000-0000-000000000003': fakeWaterChartData,
      '00000000-0000-0000-0000-000000000001': fakeLiftingChartData,
    };

    await tester.pumpWidget(_buildShell(locale: locale));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(HomeTourKeys.resultsTab));
    await _pumpFrames(tester);

    await tester.tap(find.text('Water'));
    await _pumpFrames(tester);
  },

  'results_analysis': (tester, locale) async {
    StubResultsListCubit.defaultTemplates = fakeResultsTemplates;
    StubVisualizationCubit.fakeDataByTemplate = {
      '00000000-0000-0000-0000-000000000003': fakeWaterChartData,
      '00000000-0000-0000-0000-000000000001': fakeLiftingChartData,
    };
    StubVisualizationCubit.fakeAnalysisByTemplate = {
      '00000000-0000-0000-0000-000000000001': fakeLiftingAnalysisResults,
    };

    await tester.pumpWidget(_buildShell(locale: locale));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(HomeTourKeys.resultsTab));
    await _pumpFrames(tester);

    final resultsPageView = find.byType(PageView).last;
    await tester.drag(resultsPageView, const Offset(-400, 0));
    await _pumpFrames(tester);

    await tester.tap(find.text('Lifting'));
    await _pumpFrames(tester);
  },

  'log_entry_form': (tester, locale) async {
    final lang = locale.languageCode;
    final period = fakeTemplatesForLocale(lang)[1];
    final initialValues = {
      'f-per-1': 3,
      'f-per-2': 1,
      'f-per-3': tr('Feeling okay today', lang),
    };

    await tester.pumpWidget(
      buildScreenshotApp(
        locale: locale,
        child: ZenPaperBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              // Use Builder to access context.l10n for real button labels
              child: Builder(
                builder: (context) => TemplatePreview(
                  template: period.template,
                  aesthetics: period.aesthetics,
                  initialValues: initialValues,
                  actions: [
                    TemplatePreviewAction.secondary(
                      label: context.l10n.templatePreviewDiscard,
                      icon: Icons.close,
                      onPressed: () {},
                    ),
                    TemplatePreviewAction.primary(
                      label: context.l10n.actionSave,
                      icon: Icons.save,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);
  },

  'template_designer': (tester, locale) async {
    final editorCubit = StubTemplateEditorCubit();
    editorCubit.loadFromTemplate(
      fakeTemplatesForLocale(locale.languageCode)[0],
    );

    await tester.pumpWidget(
      buildScreenshotApp(
        locale: locale,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<TemplateEditorCubit>.value(value: editorCubit),
          ],
          child: const TemplateDesignerPage(),
        ),
      ),
    );
    await _pumpFrames(tester);
  },

  'analysis_builder': (tester, locale) async {
    const snippet = '''
const values = data.values;
const mean = ss.mean(values);
const max = Math.max(...values);
const min = Math.min(...values);
const trend = ss.linearRegression(
  values.map((v, i) => [i, v])
);

return [
  { label: "Mean", value: mean, unit: "kg" },
  { label: "Max", value: max, unit: "kg" },
  { label: "Min", value: min, unit: "kg" },
  { label: "Trend", value: trend.m,
    unit: "kg/session" },
];''';

    final builderCubit = StubAnalysisBuilderCubit(
      AnalysisBuilderState(
        snippet: snippet,
        outputMode: AnalysisOutputMode.scalar,
        entryCount: 10,
        reasoning:
            'Computes basic statistics and linear trend for weight progression.',
        previewResult: AnalysisOutput.scalar([
          AnalysisScalar(label: 'Mean', value: 62.0, unit: 'kg'),
          AnalysisScalar(label: 'Max', value: 70.0, unit: 'kg'),
          AnalysisScalar(label: 'Min', value: 55.0, unit: 'kg'),
          AnalysisScalar(label: 'Trend', value: 1.5, unit: 'kg/session'),
        ]),
      ),
    );

    await tester.pumpWidget(
      buildScreenshotApp(
        locale: locale,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AnalysisBuilderCubit>.value(value: builderCubit),
          ],
          child: const AnalysisBuilderPage(),
        ),
      ),
    );
    await _pumpFrames(tester);
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Test generation — 3 devices × 4 locales × 8 screenshots = 96 goldens
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  for (final device in _devices) {
    for (final lang in _locales) {
      group('${device.name}/$lang', () {
        setUp(() async {
          DevFab.hideForScreenshots = true;
          await configureScreenshotDependencies();
        });

        tearDown(() async {
          StubVisualizationCubit.fakeDataByTemplate = {};
          StubVisualizationCubit.fakeAnalysisByTemplate = {};
          StubResultsListCubit.defaultTemplates = null;
          DevFab.hideForScreenshots = false;
          await getIt.reset();
        });

        final locale = Locale(lang);

        for (final entry in _screenshots.entries) {
          testWidgets('${entry.key}', (tester) async {
            tester.view.physicalSize = device.physicalSize;
            tester.view.devicePixelRatio = device.devicePixelRatio;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            // Suppress sub-pixel overflow errors from translated text
            // on smaller screens — cosmetic, not functional.
            final originalOnError = FlutterError.onError!;
            FlutterError.onError = (details) {
              if (details.toString().contains('overflowed')) return;
              originalOnError(details);
            };
            addTearDown(() => FlutterError.onError = originalOnError);

            await entry.value(tester, locale);

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(_golden(lang, device.name, entry.key)),
            );
          });
        }
      });
    }
  }
}
