import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_export_cubit.dart';
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_export_state.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_export_service.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/shareable_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';

@GenerateMocks([TemplateExportService])
import 'template_sharing_export_cubit_test.mocks.dart';

void main() {
  late MockTemplateExportService mockExportService;

  setUp(() {
    mockExportService = MockTemplateExportService();
  });

  TemplateWithAesthetics createTestTemplate() {
    return TemplateWithAesthetics(
      template: TrackerTemplateModel(
        id: 'test-template-id',
        name: 'Test Template',
        fields: [],
        updatedAt: DateTime(2026, 1, 1),
      ),
      aesthetics: TemplateAestheticsModel.defaults(
        templateId: 'test-template-id',
      ),
    );
  }

  AuthorCredit createTestAuthor() {
    return const AuthorCredit(name: 'Test Author');
  }

  group('TemplateSharingExportCubit', () {
    test('initial state is idle', () {
      final cubit = TemplateSharingExportCubit(mockExportService);
      addTearDown(cubit.close);

      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.availablePipelines, isEmpty);
      expect(cubit.state.shareResult, isNull);
      expect(cubit.state.exportedJson, isNull);
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);
    });

    group('loadAvailablePipelines', () {
      final testPipelines = [
        const AnalysisPipelineInfo(
          id: 'pipe-1',
          name: 'Pipeline 1',
          description: 'Test pipeline',
        ),
        const AnalysisPipelineInfo(
          id: 'pipe-2',
          name: 'Pipeline 2',
        ),
      ];

      blocTest<TemplateSharingExportCubit, TemplateSharingExportState>(
        'emits loading then success with pipeline list',
        build: () {
          when(mockExportService.getAvailablePipelines('field-1'))
              .thenAnswer((_) async => testPipelines);
          return TemplateSharingExportCubit(mockExportService);
        },
        act: (cubit) => cubit.loadAvailablePipelines('field-1'),
        expect: () => [
          const TemplateSharingExportState(status: UiFlowStatus.loading),
          TemplateSharingExportState(
            status: UiFlowStatus.success,
            lastOperation: TemplateSharingExportOperation.loadPipelines,
            availablePipelines: testPipelines,
          ),
        ],
        verify: (_) {
          verify(mockExportService.getAvailablePipelines('field-1')).called(1);
        },
      );

      blocTest<TemplateSharingExportCubit, TemplateSharingExportState>(
        'emits loading then failure on error',
        build: () {
          when(mockExportService.getAvailablePipelines('field-1'))
              .thenThrow(Exception('load failed'));
          return TemplateSharingExportCubit(mockExportService);
        },
        act: (cubit) => cubit.loadAvailablePipelines('field-1'),
        expect: () => [
          const TemplateSharingExportState(status: UiFlowStatus.loading),
          predicate<TemplateSharingExportState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });

    group('exportTemplate', () {
      blocTest<TemplateSharingExportCubit, TemplateSharingExportState>(
        'calls export service with correct arguments',
        build: () {
          when(mockExportService.exportTemplate(
            templateWithAesthetics: anyNamed('templateWithAesthetics'),
            author: anyNamed('author'),
            description: anyNamed('description'),
            includedPipelineIds: anyNamed('includedPipelineIds'),
          )).thenAnswer((_) async => '{"version":"1.0"}');
          return TemplateSharingExportCubit(mockExportService);
        },
        act: (cubit) => cubit.exportTemplate(
          templateWithAesthetics: createTestTemplate(),
          author: createTestAuthor(),
          description: 'A test template',
          pipelineIds: ['pipe-1'],
        ),
        verify: (_) {
          verify(mockExportService.exportTemplate(
            templateWithAesthetics: anyNamed('templateWithAesthetics'),
            author: anyNamed('author'),
            description: 'A test template',
            includedPipelineIds: ['pipe-1'],
          )).called(1);
        },
      );

      blocTest<TemplateSharingExportCubit, TemplateSharingExportState>(
        'emits loading then failure on service error',
        build: () {
          when(mockExportService.exportTemplate(
            templateWithAesthetics: anyNamed('templateWithAesthetics'),
            author: anyNamed('author'),
            description: anyNamed('description'),
            includedPipelineIds: anyNamed('includedPipelineIds'),
          )).thenThrow(Exception('export failed'));
          return TemplateSharingExportCubit(mockExportService);
        },
        act: (cubit) => cubit.exportTemplate(
          templateWithAesthetics: createTestTemplate(),
          author: createTestAuthor(),
        ),
        expect: () => [
          const TemplateSharingExportState(status: UiFlowStatus.loading),
          predicate<TemplateSharingExportState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });
  });
}
