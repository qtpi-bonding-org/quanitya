@Tags(['screenshot'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/design_system/widgets/quanitya/general/zen_paper_background.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quanitya_flutter/features/hidden_visibility/cubits/hidden_visibility_cubit.dart';
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
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_message_mapper.dart';
import 'package:quanitya_flutter/logic/analysis/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_output.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/template_editor_message_mapper.dart';

import 'screenshot_bootstrap.dart';
import 'stubs/fake_template_data.dart';
import 'stubs/stub_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// iPhone 16 Pro Max: 1320x2868 physical, 3x DPR = 440x956 logical
void _setIPhoneProMaxSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3.0;
}

/// Pump several frames instead of pumpAndSettle (timeouts with stream cubits).
Future<void> _pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Build the NotebookShell wrapped in all required providers.
Widget _buildShell() {
  return buildScreenshotApp(
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

void main() {
  group('Store Screenshots', () {
    setUp(() async {
      await configureScreenshotDependencies();
    });

    tearDown(() async {
      // Reset static data on factory stubs
      StubVisualizationCubit.fakeDataByTemplate = {};
      StubVisualizationCubit.fakeAnalysisByTemplate = {};
      StubResultsListCubit.defaultTemplates = null;
      await getIt.reset();
    });

    // ─────────────────────────────────────────────────────────────────────
    // 1. Temporal Present — home screen with template cards
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('1 — temporal present', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildShell());
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/temporal_present.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 2. Temporal Past — timeline of past log entries
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('2 — temporal past', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Populate timeline with fake past entries
      final timelineCubit =
          getIt<TimelineDataCubit>() as StubTimelineDataCubit;
      timelineCubit.emitPastData(fakePastTimelineItems);

      await tester.pumpWidget(_buildShell());
      await _pumpFrames(tester);

      // Swipe right to show the past (-t) tab
      await tester.drag(
        find.byType(PageView),
        const Offset(400, 0),
      );
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/temporal_past.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 3. Temporal Future — scheduled reminders
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('3 — temporal future', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Populate schedules for future tab
      final scheduleCubit =
          getIt<ScheduleListCubit>() as StubScheduleListCubit;
      scheduleCubit.emitSchedules(fakeSchedules);

      await tester.pumpWidget(_buildShell());
      await _pumpFrames(tester);

      // Swipe left to show the future (+t) tab
      await tester.drag(
        find.byType(PageView),
        const Offset(-400, 0),
      );
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/temporal_future.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 4. Graph — Water intake visualization with chart
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('4 — results graphs', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set static data so factory-created ResultsListCubits auto-populate
      StubResultsListCubit.defaultTemplates = fakeResultsTemplates;

      // Set up chart data for when folds expand
      StubVisualizationCubit.fakeDataByTemplate = {
        '00000000-0000-0000-0000-000000000003': fakeWaterChartData,
        '00000000-0000-0000-0000-000000000001': fakeLiftingChartData,
      };

      await tester.pumpWidget(_buildShell());
      await _pumpFrames(tester);

      // Tap the Results tab
      await tester.tap(find.byKey(HomeTourKeys.resultsTab));
      await _pumpFrames(tester);

      // Expand the Water fold (first one) by tapping its header
      await tester.tap(find.text('Water'));
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/results_graphs.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 5. Analysis — Lifting volume analysis with charts
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('5 — results analysis', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set static data with analysis results for Lifting
      StubResultsListCubit.defaultTemplates = fakeResultsTemplates;
      StubVisualizationCubit.fakeDataByTemplate = {
        '00000000-0000-0000-0000-000000000003': fakeWaterChartData,
        '00000000-0000-0000-0000-000000000001': fakeLiftingChartData,
      };
      StubVisualizationCubit.fakeAnalysisByTemplate = {
        '00000000-0000-0000-0000-000000000001': fakeLiftingAnalysisResults,
      };

      await tester.pumpWidget(_buildShell());
      await _pumpFrames(tester);

      // Tap the Results tab
      await tester.tap(find.byKey(HomeTourKeys.resultsTab));
      await _pumpFrames(tester);

      // Swipe left to show the analysis sub-page
      final resultsPageView = find.byType(PageView).last;
      await tester.drag(resultsPageView, const Offset(-400, 0));
      await _pumpFrames(tester);

      // Expand the Lifting fold by tapping its header
      await tester.tap(find.text('Lifting'));
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/results_analysis.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 6. Log Entry — the actual log entry form for a template
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('6 — log entry form', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Show the log entry form with the Period template's aesthetics
      // (pink colors, flower icon) — demonstrates how aesthetics look in use.
      final period = fakeTemplates[1]; // Period 🌸
      final initialValues = {
        'f-per-1': 3,           // Flow Intensity (1-5 slider)
        'f-per-2': 1,           // Cramps (1-5 slider)
        'f-per-3': 'Feeling okay today', // Notes
      };

      await tester.pumpWidget(
        buildScreenshotApp(
          child: ZenPaperBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: TemplatePreview(
                  template: period.template,
                  aesthetics: period.aesthetics,
                  initialValues: initialValues,
                  actions: [
                    TemplatePreviewAction.secondary(
                      label: 'Discard',
                      icon: Icons.close,
                      onPressed: () {},
                    ),
                    TemplatePreviewAction.primary(
                      label: 'Save',
                      icon: Icons.save,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/log_entry_form.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 7. Template Designer — field editor page
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('7 — template designer', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create editor cubit pre-populated with the Lifting template
      final editorCubit = StubTemplateEditorCubit();
      editorCubit.loadFromTemplate(fakeTemplates[0]);

      await tester.pumpWidget(
        buildScreenshotApp(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<TemplateEditorCubit>.value(value: editorCubit),
            ],
            child: const TemplateDesignerPage(),
          ),
        ),
      );
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/template_designer.png'),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // 8. Analysis Builder — JS code editor with results
    // ─────────────────────────────────────────────────────────────────────

    testWidgets('8 — analysis builder', (tester) async {
      _setIPhoneProMaxSize(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pre-populate with a JS snippet and scalar results
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
          reasoning: 'Computes basic statistics and linear trend for weight progression.',
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
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AnalysisBuilderCubit>.value(value: builderCubit),
            ],
            child: const AnalysisBuilderPage(),
          ),
        ),
      );
      await _pumpFrames(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/en/analysis_builder.png'),
      );
    });
  });
}
