import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/data/interfaces/analysis_script_interface.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_cubit.dart';
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_state.dart';
import 'package:quanitya_flutter/logic/analysis/enums/analysis_output_mode.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_enums.dart';
import 'package:quanitya_flutter/logic/analysis/models/analysis_script.dart';
import 'package:quanitya_flutter/logic/analysis/services/ai/ai_analysis_orchestrator.dart';
import 'package:quanitya_flutter/logic/analysis/services/field_shape_resolver.dart';
import 'package:quanitya_flutter/logic/analysis/services/streaming_analytics_service.dart';
import 'package:quanitya_flutter/logic/analysis/services/wasm_analysis_service.dart';

class MockScriptRepository extends Mock implements IAnalysisScriptRepository {}

class MockTemplateRepository extends Mock
    implements TemplateWithAestheticsRepository {}

class MockAiOrchestrator extends Mock implements AiAnalysisOrchestrator {}

class MockFieldShapeResolver extends Mock implements FieldShapeResolver {}

class MockStreamingService extends Mock implements StreamingAnalyticsService {}

class MockWasmService extends Mock implements IWasmAnalysisService {}

class FakeAnalysisScript extends Fake implements AnalysisScriptModel {}

void main() {
  late MockScriptRepository mockScriptRepo;
  late MockTemplateRepository mockTemplateRepo;
  late MockAiOrchestrator mockAiOrchestrator;
  late MockFieldShapeResolver mockFieldShapeResolver;
  late MockStreamingService mockStreamingService;
  late MockWasmService mockWasmService;

  setUpAll(() {
    registerFallbackValue(FakeAnalysisScript());
    registerFallbackValue(AnalysisOutputMode.scalar);
    registerFallbackValue(AnalysisSnippetLanguage.js);
  });

  setUp(() {
    mockScriptRepo = MockScriptRepository();
    mockTemplateRepo = MockTemplateRepository();
    mockAiOrchestrator = MockAiOrchestrator();
    mockFieldShapeResolver = MockFieldShapeResolver();
    mockStreamingService = MockStreamingService();
    mockWasmService = MockWasmService();
  });

  AnalysisBuilderCubit createCubit() => AnalysisBuilderCubit(
        mockScriptRepo,
        mockTemplateRepo,
        mockAiOrchestrator,
        mockFieldShapeResolver,
        mockStreamingService,
        mockWasmService,
      );

  group('AnalysisBuilderCubit', () {
    test('initial state is idle with empty defaults', () {
      final cubit = createCubit();
      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.fieldId, isNull);
      expect(cubit.state.templateId, isNull);
      expect(cubit.state.snippet, '');
      expect(cubit.state.reasoning, '');
      expect(cubit.state.outputMode, AnalysisOutputMode.scalar);
      expect(cubit.state.snippetLanguage, AnalysisSnippetLanguage.js);
      expect(cubit.state.availableScripts, isEmpty);
      expect(cubit.state.selectedScriptId, isNull);
      expect(cubit.state.previewResult, isNull);
      expect(cubit.state.livePreviewEnabled, false);
      expect(cubit.state.entryCount, 0);
      cubit.close();
    });

    group('initializeForField', () {
      blocTest<AnalysisBuilderCubit, AnalysisBuilderState>(
        'loads existing scripts and sets field context',
        build: () {
          final script = AnalysisScriptModel(
            id: 'script-1',
            name: 'Mean',
            fieldId: 'tmpl-1:Mood',
            outputMode: AnalysisOutputMode.scalar,
            snippetLanguage: AnalysisSnippetLanguage.js,
            snippet: 'return mean(values);',
            reasoning: 'Calculates average',
            updatedAt: DateTime(2026, 1, 1),
          );

          when(() => mockTemplateRepo.findById('tmpl-1'))
              .thenAnswer((_) async => null);
          when(() => mockScriptRepo.getScriptsForField('tmpl-1:Mood'))
              .thenAnswer((_) async => [script]);
          when(() => mockScriptRepo.countEntriesForTemplate('tmpl-1'))
              .thenAnswer((_) async => 42);

          return createCubit();
        },
        act: (cubit) => cubit.initializeForField(
          'Mood',
          null,
          templateId: 'tmpl-1',
        ),
        expect: () => [
          // Loading state
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.loading),
          // Success state with loaded data
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.success)
              .having((s) => s.fieldId, 'fieldId', 'Mood')
              .having((s) => s.templateId, 'templateId', 'tmpl-1')
              .having((s) => s.entryCount, 'entryCount', 42)
              .having((s) => s.snippet, 'snippet', 'return mean(values);')
              .having((s) => s.reasoning, 'reasoning', 'Calculates average')
              .having((s) => s.selectedScriptId, 'selectedScriptId', 'script-1')
              .having(
                  (s) => s.availableScripts.length, 'availableScripts', 1),
        ],
      );

      blocTest<AnalysisBuilderCubit, AnalysisBuilderState>(
        'handles no existing scripts gracefully',
        build: () {
          when(() => mockTemplateRepo.findById('tmpl-1'))
              .thenAnswer((_) async => null);
          when(() => mockScriptRepo.getScriptsForField('tmpl-1:Mood'))
              .thenAnswer((_) async => []);
          when(() => mockScriptRepo.getAllScripts())
              .thenAnswer((_) async => []);
          when(() => mockScriptRepo.countEntriesForTemplate('tmpl-1'))
              .thenAnswer((_) async => 0);

          return createCubit();
        },
        act: (cubit) => cubit.initializeForField(
          'Mood',
          null,
          templateId: 'tmpl-1',
        ),
        expect: () => [
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.loading),
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.success)
              .having((s) => s.snippet, 'snippet', analysisHintSnippet)
              .having((s) => s.selectedScriptId, 'selectedScriptId', isNull)
              .having((s) => s.availableScripts, 'availableScripts', isEmpty),
        ],
      );
    });

    group('synchronous state mutations', () {
      test('selectScript updates snippet and output mode from existing script',
          () {
        final cubit = createCubit();
        final script = AnalysisScriptModel(
          id: 'script-1',
          name: 'Mean',
          fieldId: 'tmpl-1:Mood',
          outputMode: AnalysisOutputMode.vector,
          snippetLanguage: AnalysisSnippetLanguage.js,
          snippet: 'return timeSeries(values);',
          reasoning: 'Time series view',
          updatedAt: DateTime(2026, 1, 1),
        );

        // Seed available scripts into state
        cubit.emit(cubit.state.copyWith(availableScripts: [script]));

        cubit.selectScript('script-1');

        expect(cubit.state.selectedScriptId, 'script-1');
        expect(cubit.state.snippet, 'return timeSeries(values);');
        expect(cubit.state.reasoning, 'Time series view');
        expect(cubit.state.outputMode, AnalysisOutputMode.vector);
        cubit.close();
      });

      test('selectScript does nothing for unknown script ID', () {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(snippet: 'existing'));

        cubit.selectScript('nonexistent');

        expect(cubit.state.snippet, 'existing');
        expect(cubit.state.selectedScriptId, isNull);
        cubit.close();
      });

      test('newScript clears all editor state', () {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(
          selectedScriptId: 'script-1',
          snippet: 'some code',
          reasoning: 'some reason',
          outputMode: AnalysisOutputMode.matrix,
          entryRangeStart: 10,
          entryRangeEnd: 50,
        ));

        cubit.newScript();

        expect(cubit.state.selectedScriptId, isNull);
        expect(cubit.state.snippet, analysisHintSnippet);
        expect(cubit.state.reasoning, '');
        expect(cubit.state.outputMode, AnalysisOutputMode.scalar);
        expect(cubit.state.previewResult, isNull);
        cubit.close();
      });

      test('setOutputMode updates output mode', () {
        final cubit = createCubit();

        cubit.setOutputMode(AnalysisOutputMode.matrix);

        expect(cubit.state.outputMode, AnalysisOutputMode.matrix);
        cubit.close();
      });

      test('updateSnippet updates snippet text', () {
        final cubit = createCubit();

        cubit.updateSnippet('return mean(values);');

        expect(cubit.state.snippet, 'return mean(values);');
        cubit.close();
      });

      test('applySuggestion sets all suggestion fields', () {
        final cubit = createCubit();

        cubit.applySuggestion(
          snippet: 'return std(values);',
          reasoning: 'Standard deviation',
          outputMode: AnalysisOutputMode.scalar,
          snippetLanguage: AnalysisSnippetLanguage.js,
        );

        expect(cubit.state.snippet, 'return std(values);');
        expect(cubit.state.reasoning, 'Standard deviation');
        expect(cubit.state.outputMode, AnalysisOutputMode.scalar);
        expect(cubit.state.lastOperation,
            ScriptBuilderOperation.applyAiSuggestion);
        expect(cubit.state.status, UiFlowStatus.success);
        cubit.close();
      });

      test('setEntryRange sets start and end', () {
        final cubit = createCubit();

        cubit.setEntryRange(start: 10, end: 50);

        expect(cubit.state.entryRangeStart, 10);
        expect(cubit.state.entryRangeEnd, 50);
        cubit.close();
      });

      test('setEntryRange with null clears range', () {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(
          entryRangeStart: 10,
          entryRangeEnd: 50,
        ));

        cubit.setEntryRange();

        expect(cubit.state.entryRangeStart, isNull);
        expect(cubit.state.entryRangeEnd, isNull);
        cubit.close();
      });

      test('setSelectedFieldForAi updates field selection', () {
        final cubit = createCubit();

        cubit.setSelectedFieldForAi('Energy');

        expect(cubit.state.selectedFieldForAi, 'Energy');
        cubit.close();
      });

      test('finishBranches sets branchesFinished to true', () {
        final cubit = createCubit();

        cubit.finishBranches();

        expect(cubit.state.branchesFinished, true);
        cubit.close();
      });

      test('editBranches sets branchesFinished to false', () {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(branchesFinished: true));

        cubit.editBranches();

        expect(cubit.state.branchesFinished, false);
        cubit.close();
      });
    });

    group('live preview', () {
      test('toggleLivePreview enables then disables', () {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(fieldId: 'Mood'));

        when(() => mockStreamingService.streamResultsForLivePreview(
              snippet: any(named: 'snippet'),
              fieldId: any(named: 'fieldId'),
              outputMode: any(named: 'outputMode'),
              snippetLanguage: any(named: 'snippetLanguage'),
              templateId: any(named: 'templateId'),
            )).thenAnswer((_) => const Stream.empty());

        cubit.toggleLivePreview();
        expect(cubit.state.livePreviewEnabled, true);

        cubit.toggleLivePreview();
        expect(cubit.state.livePreviewEnabled, false);
        expect(cubit.state.liveResults, isNull);
        cubit.close();
      });

      test('startLivePreview does nothing when fieldId is null', () {
        final cubit = createCubit();

        cubit.startLivePreview();

        expect(cubit.state.livePreviewEnabled, false);
        verifyNever(() => mockStreamingService.streamResultsForLivePreview(
              snippet: any(named: 'snippet'),
              fieldId: any(named: 'fieldId'),
              outputMode: any(named: 'outputMode'),
              snippetLanguage: any(named: 'snippetLanguage'),
              templateId: any(named: 'templateId'),
            ));
        cubit.close();
      });
    });

    group('saveScript', () {
      blocTest<AnalysisBuilderCubit, AnalysisBuilderState>(
        'saves script to repository and reloads list',
        build: () {
          when(() => mockScriptRepo.saveScript(any()))
              .thenAnswer((_) async {});
          when(() => mockScriptRepo.getScriptsForField('tmpl-1:Mood'))
              .thenAnswer((_) async => [
                    AnalysisScriptModel(
                      id: 'new-id',
                      name: 'My Script',
                      fieldId: 'tmpl-1:Mood',
                      outputMode: AnalysisOutputMode.scalar,
                      snippetLanguage: AnalysisSnippetLanguage.js,
                      snippet: 'return mean(values);',
                      updatedAt: DateTime(2026, 1, 1),
                    ),
                  ]);

          return createCubit();
        },
        seed: () => const AnalysisBuilderState(
          fieldId: 'Mood',
          templateId: 'tmpl-1',
          snippet: 'return mean(values);',
          outputMode: AnalysisOutputMode.scalar,
          snippetLanguage: AnalysisSnippetLanguage.js,
        ),
        act: (cubit) => cubit.saveScript('My Script'),
        expect: () => [
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.loading),
          isA<AnalysisBuilderState>()
              .having((s) => s.status, 'status', UiFlowStatus.success)
              .having((s) => s.lastOperation, 'op',
                  ScriptBuilderOperation.saveScript)
              .having(
                  (s) => s.availableScripts.length, 'scripts count', 1),
        ],
        verify: (_) {
          verify(() => mockScriptRepo.saveScript(any())).called(1);
        },
      );
    });

    group('runScript', () {
      test('does nothing when snippet is empty', () async {
        final localWasm = MockWasmService();
        final cubit = AnalysisBuilderCubit(
          mockScriptRepo,
          mockTemplateRepo,
          mockAiOrchestrator,
          mockFieldShapeResolver,
          mockStreamingService,
          localWasm,
        );

        await cubit.runScript();

        expect(cubit.state.status, UiFlowStatus.idle);
        verifyNever(() => localWasm.execute(any()));
        cubit.close();
      });
    });

    group('close', () {
      test('cancels live results subscription', () async {
        final cubit = createCubit();
        cubit.emit(cubit.state.copyWith(fieldId: 'Mood'));

        when(() => mockStreamingService.streamResultsForLivePreview(
              snippet: any(named: 'snippet'),
              fieldId: any(named: 'fieldId'),
              outputMode: any(named: 'outputMode'),
              snippetLanguage: any(named: 'snippetLanguage'),
              templateId: any(named: 'templateId'),
            )).thenAnswer((_) => const Stream.empty());

        cubit.startLivePreview();
        expect(cubit.state.livePreviewEnabled, true);

        await cubit.close();
        // No exception = subscription was cancelled cleanly
      });
    });
  });
}
