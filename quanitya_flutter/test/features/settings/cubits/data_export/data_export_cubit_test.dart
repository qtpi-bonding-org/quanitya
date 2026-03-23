import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quanitya_flutter/data/repositories/data_export_repository.dart';

@GenerateMocks([DataExportRepository])
import 'data_export_cubit_test.mocks.dart';

final _fakeFile = XFile.fromData(
  Uint8List.fromList([]),
  name: 'test.json',
  mimeType: 'application/json',
);

void main() {
  group('DataExportCubit', () {
    late MockDataExportRepository mockRepo;

    setUp(() {
      mockRepo = MockDataExportRepository();
    });

    DataExportCubit buildCubit() => DataExportCubit(mockRepo);

    test('initial state is idle', () {
      final cubit = buildCubit();

      expect(cubit.state.status, equals(UiFlowStatus.idle));
      expect(cubit.state.lastOperation, isNull);
      expect(cubit.state.error, isNull);

      cubit.close();
    });

    group('getExportableTableNames', () {
      test('delegates to repository', () {
        final tables = ['tracker_templates', 'log_entries', 'schedules'];
        when(mockRepo.getExportableTableNames()).thenReturn(tables);

        final cubit = buildCubit();
        final result = cubit.getExportableTableNames();

        expect(result, equals(tables));
        verify(mockRepo.getExportableTableNames()).called(1);

        cubit.close();
      });
    });

    group('exportData', () {
      final selectedTables = {'tracker_templates', 'log_entries'};

      test('emits loading then success on successful export', () async {
        when(mockRepo.prepareExportFile(selectedTables))
            .thenAnswer((_) async => _fakeFile);
        when(mockRepo.shareExportFile(any))
            .thenAnswer((_) async => DataExportResult.success);

        final cubit = buildCubit();
        final states = <DataExportState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.exportData(selectedTables);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.success));
        expect(states.last.lastOperation, equals(DataExportOperation.export));

        verify(mockRepo.prepareExportFile(selectedTables)).called(1);
        verify(mockRepo.shareExportFile(any)).called(1);
      });

      test('emits loading then idle when export is cancelled', () async {
        when(mockRepo.prepareExportFile(selectedTables))
            .thenAnswer((_) async => _fakeFile);
        when(mockRepo.shareExportFile(any))
            .thenAnswer((_) async => DataExportResult.cancelled);

        final cubit = buildCubit();
        final states = <DataExportState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.exportData(selectedTables);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.idle));
      });
    });

    group('pickImportFile', () {
      test('returns table names on success', () async {
        final tables = ['tracker_templates', 'log_entries'];
        when(mockRepo.parseImportFile()).thenAnswer((_) async => tables);

        final cubit = buildCubit();
        await cubit.pickImportFile();

        expect(cubit.state.pickedTableNames, equals(tables));
        verify(mockRepo.parseImportFile()).called(1);

        await cubit.close();
      });

      test('stays idle when user cancels file picker', () async {
        when(mockRepo.parseImportFile())
            .thenThrow(const ImportCancelledException());

        final cubit = buildCubit();
        await cubit.pickImportFile();

        expect(cubit.state.pickedTableNames, isEmpty);
        expect(cubit.state.status, equals(UiFlowStatus.idle));

        await cubit.close();
      });

      test('emits error on invalid file', () async {
        when(mockRepo.parseImportFile())
            .thenThrow(const ImportFailedException('Invalid file'));

        final cubit = buildCubit();
        await cubit.pickImportFile();

        expect(cubit.state.pickedTableNames, isEmpty);
        expect(cubit.state.status, equals(UiFlowStatus.failure));
        expect(cubit.state.error, isA<ImportFailedException>());

        await cubit.close();
      });
    });

    group('importData', () {
      final selectedTables = {'tracker_templates', 'log_entries'};

      test('emits loading then success on successful import', () async {
        when(mockRepo.importData(selectedTables))
            .thenAnswer((_) async {});

        final cubit = buildCubit();
        final states = <DataExportState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.importData(selectedTables);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.success));
        expect(
          states.last.lastOperation,
          equals(DataExportOperation.importData),
        );

        verify(mockRepo.importData(selectedTables)).called(1);
      });

      test('emits loading then failure on import error', () async {
        when(mockRepo.importData(selectedTables))
            .thenThrow(const ImportFailedException('DB error'));

        final cubit = buildCubit();
        final states = <DataExportState>[];
        final subscription = cubit.stream.listen(states.add);

        await cubit.importData(selectedTables);
        await Future.delayed(Duration.zero);

        await subscription.cancel();
        await cubit.close();

        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first.status, equals(UiFlowStatus.loading));
        expect(states.last.status, equals(UiFlowStatus.failure));
      });
    });
  });
}
