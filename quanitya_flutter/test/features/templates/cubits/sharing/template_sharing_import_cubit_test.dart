import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_import_cubit.dart';
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_import_state.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/template_import_service.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/shareable_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_aesthetics.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';

@GenerateMocks([TemplateImportService])
import 'template_sharing_import_cubit_test.mocks.dart';

void main() {
  late MockTemplateImportService mockImportService;

  setUp(() {
    mockImportService = MockTemplateImportService();
  });

  ShareableTemplate createTestShareable() {
    return ShareableTemplate(
      version: '1.0',
      category: 'test',
      author: const AuthorCredit(name: 'Test Author'),
      template: TrackerTemplateModel(
        id: 'shared-id',
        name: 'Shared Template',
        fields: [],
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  TemplateWithAesthetics createImportedTemplate() {
    return TemplateWithAesthetics(
      template: TrackerTemplateModel(
        id: 'imported-id',
        name: 'Shared Template',
        fields: [],
        updatedAt: DateTime(2026, 1, 1),
      ),
      aesthetics: TemplateAestheticsModel.defaults(
        templateId: 'imported-id',
      ),
    );
  }

  const testUrl = 'https://gist.githubusercontent.com/user/abc123/raw/template.json';

  group('TemplateSharingImportCubit', () {
    test('initial state is idle with no preview', () {
      final cubit = TemplateSharingImportCubit(mockImportService);
      addTearDown(cubit.close);

      expect(cubit.state.status, UiFlowStatus.idle);
      expect(cubit.state.previewUrl, isNull);
      expect(cubit.state.previewTemplate, isNull);
      expect(cubit.state.importedTemplate, isNull);
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);
    });

    group('previewFromUrl', () {
      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'emits loading then success with preview data and stored URL',
        build: () {
          when(mockImportService.previewFromUrl(testUrl))
              .thenAnswer((_) async => createTestShareable());
          return TemplateSharingImportCubit(mockImportService);
        },
        act: (cubit) => cubit.previewFromUrl(testUrl),
        expect: () => [
          const TemplateSharingImportState(status: UiFlowStatus.loading),
          predicate<TemplateSharingImportState>(
            (s) =>
                s.status == UiFlowStatus.success &&
                s.lastOperation == TemplateSharingImportOperation.preview &&
                s.previewUrl == testUrl &&
                s.previewTemplate != null &&
                s.previewTemplate!.template.name == 'Shared Template',
          ),
        ],
        verify: (_) {
          verify(mockImportService.previewFromUrl(testUrl)).called(1);
        },
      );

      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'emits loading then failure on TemplateImportException',
        build: () {
          when(mockImportService.previewFromUrl(testUrl)).thenThrow(
            const TemplateImportException(
              'Invalid URL format',
              TemplateImportErrorType.invalidUrl,
            ),
          );
          return TemplateSharingImportCubit(mockImportService);
        },
        act: (cubit) => cubit.previewFromUrl(testUrl),
        expect: () => [
          const TemplateSharingImportState(status: UiFlowStatus.loading),
          predicate<TemplateSharingImportState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });

    group('confirmImport', () {
      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'no-op when no previewUrl is set',
        build: () => TemplateSharingImportCubit(mockImportService),
        act: (cubit) => cubit.confirmImport(),
        expect: () => <TemplateSharingImportState>[],
        verify: (_) {
          verifyNever(mockImportService.importFromUrl(any));
        },
      );

      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'emits loading then success with importedTemplate',
        build: () {
          when(mockImportService.previewFromUrl(testUrl))
              .thenAnswer((_) async => createTestShareable());
          when(mockImportService.importFromUrl(testUrl))
              .thenAnswer((_) async => createImportedTemplate());
          return TemplateSharingImportCubit(mockImportService);
        },
        act: (cubit) async {
          await cubit.previewFromUrl(testUrl);
          await cubit.confirmImport();
        },
        expect: () => [
          // preview loading
          const TemplateSharingImportState(status: UiFlowStatus.loading),
          // preview success
          predicate<TemplateSharingImportState>(
            (s) =>
                s.status == UiFlowStatus.success &&
                s.lastOperation == TemplateSharingImportOperation.preview,
          ),
          // confirm loading
          predicate<TemplateSharingImportState>(
            (s) => s.status == UiFlowStatus.loading,
          ),
          // confirm success
          predicate<TemplateSharingImportState>(
            (s) =>
                s.status == UiFlowStatus.success &&
                s.lastOperation ==
                    TemplateSharingImportOperation.confirmImport &&
                s.importedTemplate != null,
          ),
        ],
        verify: (_) {
          verify(mockImportService.importFromUrl(testUrl)).called(1);
        },
      );

      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'emits loading then failure on error',
        build: () {
          when(mockImportService.previewFromUrl(testUrl))
              .thenAnswer((_) async => createTestShareable());
          when(mockImportService.importFromUrl(testUrl))
              .thenThrow(
            const TemplateImportException(
              'Network error',
              TemplateImportErrorType.networkError,
            ),
          );
          return TemplateSharingImportCubit(mockImportService);
        },
        act: (cubit) async {
          await cubit.previewFromUrl(testUrl);
          await cubit.confirmImport();
        },
        expect: () => [
          // preview loading
          const TemplateSharingImportState(status: UiFlowStatus.loading),
          // preview success
          predicate<TemplateSharingImportState>(
            (s) =>
                s.status == UiFlowStatus.success &&
                s.lastOperation == TemplateSharingImportOperation.preview,
          ),
          // confirm loading
          predicate<TemplateSharingImportState>(
            (s) => s.status == UiFlowStatus.loading,
          ),
          // confirm failure
          predicate<TemplateSharingImportState>(
            (s) => s.status == UiFlowStatus.failure && s.error != null,
          ),
        ],
      );
    });

    group('clearPreview', () {
      blocTest<TemplateSharingImportCubit, TemplateSharingImportState>(
        'resets to initial state',
        build: () {
          when(mockImportService.previewFromUrl(testUrl))
              .thenAnswer((_) async => createTestShareable());
          return TemplateSharingImportCubit(mockImportService);
        },
        act: (cubit) async {
          await cubit.previewFromUrl(testUrl);
          cubit.clearPreview();
        },
        expect: () => [
          // preview loading
          const TemplateSharingImportState(status: UiFlowStatus.loading),
          // preview success
          predicate<TemplateSharingImportState>(
            (s) =>
                s.status == UiFlowStatus.success &&
                s.previewTemplate != null,
          ),
          // clear → back to initial
          const TemplateSharingImportState(),
        ],
      );
    });
  });
}
