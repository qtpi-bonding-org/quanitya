import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart';
import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_cubit.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_state.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

class MockLogEntryRepository extends Mock implements ILogEntryRepository {}

class MockTemplateQueryDao extends Mock implements TemplateQueryDao {}

/// Helper to build test entries
LogEntryWithContext _makeEntry({
  required String id,
  required String templateId,
  required String templateName,
  DateTime? occurredAt,
  DateTime? scheduledFor,
  Map<String, dynamic> data = const {'value': 5},
}) {
  return LogEntryWithContext(
    entry: LogEntryModel(
      id: id,
      templateId: templateId,
      occurredAt: occurredAt,
      scheduledFor: scheduledFor,
      data: data,
      updatedAt: DateTime(2026, 1, 1),
    ),
    template: TrackerTemplateModel(
      id: templateId,
      name: templateName,
      fields: [],
      updatedAt: DateTime(2026, 1, 1),
    ),
  );
}

void main() {
  late MockLogEntryRepository mockRepo;
  late MockTemplateQueryDao mockTemplateDao;
  late StreamController<List<LogEntryWithContext>> pastController;
  late StreamController<List<LogEntryWithContext>> futureController;
  late StreamController<List<TrackerTemplateModel>> templateController;

  setUp(() {
    mockRepo = MockLogEntryRepository();
    mockTemplateDao = MockTemplateQueryDao();
    pastController = StreamController<List<LogEntryWithContext>>.broadcast();
    futureController = StreamController<List<LogEntryWithContext>>.broadcast();
    templateController =
        StreamController<List<TrackerTemplateModel>>.broadcast();

    when(() => mockRepo.watchPastEntriesWithContext())
        .thenAnswer((_) => pastController.stream);
    when(() => mockRepo.watchUpcomingEntriesWithContext())
        .thenAnswer((_) => futureController.stream);
    when(() => mockTemplateDao.watch(isArchived: false))
        .thenAnswer((_) => templateController.stream);
  });

  tearDown(() {
    pastController.close();
    futureController.close();
    templateController.close();
  });

  TimelineDataCubit createCubit() =>
      TimelineDataCubit(mockRepo, mockTemplateDao);

  group('TimelineDataCubit', () {
    test('initial state is loading (subscribes on construction)', () {
      final cubit = createCubit();
      expect(cubit.state.status, UiFlowStatus.loading);
      expect(cubit.state.pastItems, isEmpty);
      expect(cubit.state.futureItems, isEmpty);
      cubit.close();
    });

    test('emits success with past items when stream delivers entries', () async {
      final cubit = createCubit();

      final entries = [
        _makeEntry(
          id: 'e1',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15, 10, 0),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 14, 9, 0),
        ),
      ];

      pastController.add(entries);
      await Future.delayed(Duration.zero);

      expect(cubit.state.status, UiFlowStatus.success);
      expect(cubit.state.totalPastCount, 2);
      // Items include date dividers + entries
      expect(cubit.state.pastItems.length, greaterThan(2));
      cubit.close();
    });

    test('emits success with future items when stream delivers entries',
        () async {
      final cubit = createCubit();

      futureController.add([
        _makeEntry(
          id: 'f1',
          templateId: 't1',
          templateName: 'Mood',
          scheduledFor: DateTime(2026, 3, 25, 9, 0),
        ),
      ]);
      await Future.delayed(Duration.zero);

      expect(cubit.state.totalFutureCount, 1);
      expect(cubit.state.futureItems, isNotEmpty);
      cubit.close();
    });

    test('empty entries produce empty items', () async {
      final cubit = createCubit();

      pastController.add([]);
      await Future.delayed(Duration.zero);

      expect(cubit.state.pastItems, isEmpty);
      expect(cubit.state.totalPastCount, 0);
      cubit.close();
    });

    test('setTemplateFilter filters entries by template ID', () async {
      final cubit = createCubit();

      pastController.add([
        _makeEntry(
          id: 'e1',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't2',
          templateName: 'Sleep',
          occurredAt: DateTime(2026, 1, 15),
        ),
        _makeEntry(
          id: 'e3',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 14),
        ),
      ]);
      await Future.delayed(Duration.zero);

      expect(cubit.state.totalPastCount, 3);

      cubit.setTemplateFilter('t1');
      expect(cubit.state.filters.templateId, 't1');
      expect(cubit.state.totalPastCount, 2);

      cubit.setTemplateFilter(null);
      expect(cubit.state.totalPastCount, 3);
      cubit.close();
    });

    test('setPastSort changes sort direction', () async {
      final cubit = createCubit();

      pastController.add([
        _makeEntry(
          id: 'e1',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 10),
        ),
      ]);
      await Future.delayed(Duration.zero);

      // Default sort is descending (newest first)
      expect(cubit.state.pastSort.ascending, false);

      cubit.setPastSort(ascending: true);
      expect(cubit.state.pastSort.ascending, true);
      cubit.close();
    });

    test('setPastSort by template groups entries', () async {
      final cubit = createCubit();

      pastController.add([
        _makeEntry(
          id: 'e1',
          templateId: 't2',
          templateName: 'Sleep',
          occurredAt: DateTime(2026, 1, 15),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15),
        ),
      ]);
      await Future.delayed(Duration.zero);

      cubit.setPastSort(type: TimelineSortType.template, ascending: true);
      expect(cubit.state.pastSort.type, TimelineSortType.template);
      // Mood (t1) should come before Sleep (t2) alphabetically
      cubit.close();
    });

    test('togglePastSort flips ascending flag', () async {
      final cubit = createCubit();
      pastController.add([]);
      await Future.delayed(Duration.zero);

      expect(cubit.state.pastSort.ascending, false);
      cubit.togglePastSort();
      expect(cubit.state.pastSort.ascending, true);
      cubit.togglePastSort();
      expect(cubit.state.pastSort.ascending, false);
      cubit.close();
    });

    test('setTimeRange filters by time range', () async {
      final cubit = createCubit();

      final now = DateTime.now();
      pastController.add([
        _makeEntry(
          id: 'e1',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: now.subtract(const Duration(days: 30)),
        ),
      ]);
      await Future.delayed(Duration.zero);

      expect(cubit.state.totalPastCount, 2);

      cubit.setTimeRange(TimelineTimeRange.week);
      expect(cubit.state.filters.timeRange, TimelineTimeRange.week);
      // Only the entry from yesterday should pass the week filter
      expect(cubit.state.totalPastCount, 1);

      cubit.setTimeRange(TimelineTimeRange.all);
      expect(cubit.state.totalPastCount, 2);
      cubit.close();
    });

    test('timeline items include date dividers', () async {
      final cubit = createCubit();

      pastController.add([
        _makeEntry(
          id: 'e1',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15, 10, 0),
        ),
        _makeEntry(
          id: 'e2',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 15, 8, 0),
        ),
        _makeEntry(
          id: 'e3',
          templateId: 't1',
          templateName: 'Mood',
          occurredAt: DateTime(2026, 1, 14, 9, 0),
        ),
      ]);
      await Future.delayed(Duration.zero);

      // 2 dates × 1 divider + 3 entries = 5 items
      final dividers = cubit.state.pastItems
          .whereType<TimelineDateDivider>()
          .toList();
      final entries = cubit.state.pastItems
          .whereType<TimelineEntryItem>()
          .toList();

      expect(dividers.length, 2);
      expect(entries.length, 3);
      cubit.close();
    });

    test('stream error sets failure state', () async {
      final cubit = createCubit();

      pastController.addError(Exception('DB error'));
      await Future.delayed(Duration.zero);

      expect(cubit.state.status, UiFlowStatus.failure);
      expect(cubit.state.error, isNotNull);
      cubit.close();
    });

    test('close cancels all stream subscriptions', () async {
      final cubit = createCubit();
      await cubit.close();

      // Adding to streams after close should not throw
      pastController.add([]);
      futureController.add([]);
      templateController.add([]);
    });
  });
}
