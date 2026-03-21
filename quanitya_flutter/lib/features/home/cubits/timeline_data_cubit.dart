import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:intl/intl.dart';
import 'package:quanitya_flutter/design_system/primitives/quanitya_date_format.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../data/interfaces/log_entry_interface.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../../../data/dao/template_query_dao.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'timeline_data_state.dart';

@injectable
class TimelineDataCubit extends QuanityaCubit<TimelineDataState> {
  final ILogEntryRepository _logEntryRepo;
  final TemplateQueryDao _templateQueryDao;

  // Stream subscriptions
  StreamSubscription? _pastSubscription;
  StreamSubscription? _futureSubscription;
  StreamSubscription? _templatesSubscription;

  TimelineDataCubit(this._logEntryRepo, this._templateQueryDao)
    : super(const TimelineDataState()) {
    _initialize();
  }

  void _initialize() {
    emit(state.copyWith(status: UiFlowStatus.loading));
    _resubscribe();
    _subscribeToTemplates();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Management
  // ─────────────────────────────────────────────────────────────────────────

  void _resubscribe() {
    _pastSubscription?.cancel();
    _futureSubscription?.cancel();

    // Compute date range from current filters
    final dateRange = _computeDateRange(state.filters);

    _pastSubscription = _logEntryRepo
        .watchPastEntriesWithContext(
          templateId: state.filters.templateId,
          startDate: dateRange?.start,
          endDate: dateRange?.end,
          sortAscending: state.pastSort.ascending,
        )
        .listen(
          (entries) {
            var sorted = entries;
            if (state.pastSort.type == TimelineSortType.template) {
              sorted = List<LogEntryWithContext>.from(entries)
                ..sort((a, b) {
                  final cmp = a.template.name.compareTo(b.template.name);
                  return state.pastSort.ascending ? cmp : -cmp;
                });
            }
            final pastItems = _flattenToTimelineItems(sorted);
            emit(state.copyWith(
              pastItems: pastItems,
              totalPastCount: entries.length,
              status: UiFlowStatus.success,
              lastOperation: TimelineDataOperation.load,
            ));
          },
          onError: (e) {
            debugPrint('TimelineDataCubit: Error in past entries stream: $e');
            emit(state.copyWith(error: e, status: UiFlowStatus.failure));
          },
        );

    _futureSubscription = _logEntryRepo
        .watchUpcomingEntriesWithContext(
          templateId: state.filters.templateId,
          sortAscending: state.futureSort.ascending,
        )
        .listen(
          (entries) {
            var sorted = entries;
            if (state.futureSort.type == TimelineSortType.template) {
              sorted = List<LogEntryWithContext>.from(entries)
                ..sort((a, b) {
                  final cmp = a.template.name.compareTo(b.template.name);
                  return state.futureSort.ascending ? cmp : -cmp;
                });
            }
            final futureItems = _flattenToTimelineItems(sorted);
            emit(state.copyWith(
              futureItems: futureItems,
              totalFutureCount: entries.length,
              status: UiFlowStatus.success,
            ));
          },
          onError: (e) {
            debugPrint(
              'TimelineDataCubit: Error in upcoming entries stream: $e',
            );
            emit(state.copyWith(error: e, status: UiFlowStatus.failure));
          },
        );
  }

  ({DateTime start, DateTime end})? _computeDateRange(TimelineFilters filters) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return switch (filters.timeRange) {
      TimelineTimeRange.all => null,
      TimelineTimeRange.today => (start: todayStart, end: todayStart.add(const Duration(days: 1))),
      TimelineTimeRange.week => (
          // Match current behavior: entries within 7 days in either direction
          start: now.subtract(const Duration(days: 7)),
          end: now.add(const Duration(days: 7)),
        ),
      TimelineTimeRange.month => (start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 1)),
      TimelineTimeRange.custom => filters.customStartDate != null
          ? (
              start: filters.customStartDate!,
              end: filters.customEndDate?.add(const Duration(days: 1)) ?? now,
            )
          : null,
    };
  }

  void _subscribeToTemplates() {
    _templatesSubscription?.cancel();
    _templatesSubscription = _templateQueryDao
        .watch(isArchived: false)
        .listen((templates) {
          emit(state.copyWith(availableTemplates: templates));
        });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public Filter/Sort Methods
  // ─────────────────────────────────────────────────────────────────────────

  void setTemplateFilter(String? templateId) {
    emit(state.copyWith(
      filters: state.filters.copyWith(templateId: templateId),
      status: UiFlowStatus.loading,
    ));
    _resubscribe();
  }

  void setTimeRange(TimelineTimeRange range, {DateTime? start, DateTime? end}) {
    emit(state.copyWith(
      filters: state.filters.copyWith(
        timeRange: range,
        customStartDate: range == TimelineTimeRange.custom ? start : null,
        customEndDate: range == TimelineTimeRange.custom ? end : null,
      ),
      status: UiFlowStatus.loading,
    ));
    _resubscribe();
  }

  void setPastSort({TimelineSortType? type, bool? ascending}) {
    emit(state.copyWith(
      pastSort: state.pastSort.copyWith(
        type: type ?? state.pastSort.type,
        ascending: ascending ?? state.pastSort.ascending,
      ),
      status: UiFlowStatus.loading,
    ));
    _resubscribe();
  }

  void setFutureSort({TimelineSortType? type, bool? ascending}) {
    emit(state.copyWith(
      futureSort: state.futureSort.copyWith(
        type: type ?? state.futureSort.type,
        ascending: ascending ?? state.futureSort.ascending,
      ),
      status: UiFlowStatus.loading,
    ));
    _resubscribe();
  }

  void togglePastSort() {
    setPastSort(ascending: !state.pastSort.ascending);
  }

  void toggleFutureSort() {
    setFutureSort(ascending: !state.futureSort.ascending);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data Transformation
  // ─────────────────────────────────────────────────────────────────────────

  List<TimelineItem> _flattenToTimelineItems(
    List<LogEntryWithContext> entries,
  ) {
    if (entries.isEmpty) return [];

    // Group by date
    final grouped = <String, List<LogEntryWithContext>>{};
    for (final entry in entries) {
      final timestamp =
          entry.entry.occurredAt ?? entry.entry.scheduledFor ?? DateTime.now();
      final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }

    // Flatten to timeline items with pre-computed values
    final items = <TimelineItem>[];
    final dateKeys = grouped.keys.toList();

    // Track overall entry position for timeline line continuity
    int overallEntryIndex = 0;
    int totalEntries = entries.length;

    for (int dateIndex = 0; dateIndex < dateKeys.length; dateIndex++) {
      final dateKey = dateKeys[dateIndex];
      final dateEntries = grouped[dateKey]!;
      final isFirstDate = dateIndex == 0;

      // Add date divider with pre-computed formatted date
      final date = DateTime.parse(dateKey);
      final formattedDate =
          QuanityaDateFormat.monthDayCompact(date);

      items.add(
        TimelineItem.dateDivider(
          dateKey: dateKey,
          isFirst: isFirstDate,
          formattedDate: formattedDate,
        ),
      );

      // Add entries for this date with all pre-computed values
      for (int entryIndex = 0; entryIndex < dateEntries.length; entryIndex++) {
        final entry = dateEntries[entryIndex];
        final isFirstEntry = overallEntryIndex == 0;
        final isLastEntry = overallEntryIndex == totalEntries - 1;

        // Pre-compute all expensive operations
        final timestamp =
            entry.entry.occurredAt ??
            entry.entry.scheduledFor ??
            DateTime.now();
        final timeString = QuanityaDateFormat.time(timestamp);
        final dateString = QuanityaDateFormat.monthDay(timestamp);
        final dataPreview = _computeDataPreview(entry.entry.data);

        items.add(
          TimelineItem.entry(
            entryWithContext: entry,
            isFirst: isFirstEntry,
            isLast: isLastEntry,
            showTimeOnly: true,
            timeString: timeString,
            dateString: dateString,
            dataPreview: dataPreview,
            iconString: entry.aesthetics?.icon,
            emoji: entry.aesthetics?.emoji,
            accentColorHex: entry.aesthetics?.palette.accents.firstOrNull,
          ),
        );

        overallEntryIndex++;
      }
    }

    return items;
  }

  /// Pre-compute data preview string
  String _computeDataPreview(Map<String, dynamic> data) {
    if (data.isEmpty) return '';
    final firstValue = data.values.first;
    return firstValue.toString();
  }

  @override
  Future<void> close() {
    _pastSubscription?.cancel();
    _futureSubscription?.cancel();
    _templatesSubscription?.cancel();
    return super.close();
  }
}
