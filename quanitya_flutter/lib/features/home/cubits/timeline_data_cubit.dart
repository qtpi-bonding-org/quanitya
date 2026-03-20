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

  // Raw data from streams
  List<LogEntryWithContext> _rawPastEntries = [];
  List<LogEntryWithContext> _rawFutureEntries = [];

  // Cache for expensive operations
  final Map<String, List<LogEntryWithContext>> _templateFilterCache = {};
  final Map<String, List<LogEntryWithContext>> _dateFilterCache = {};

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
    _subscribeToData();
  }

  void _subscribeToData() {
    _subscribeToEntries();
    _subscribeToTemplates();
  }

  void _subscribeToEntries() {
    _pastSubscription?.cancel();
    _futureSubscription?.cancel();

    // Watch past entries
    _pastSubscription = _logEntryRepo
        .watchPastEntriesWithContext()
        .listen(
          (entries) {
            debugPrint(
              'TimelineDataCubit: Received ${entries.length} past entries',
            );
            _rawPastEntries = entries;
            _invalidateAllCaches();
            _processAndEmit();
          },
          onError: (e) {
            debugPrint('TimelineDataCubit: Error in past entries stream: $e');
            emit(state.copyWith(error: e, status: UiFlowStatus.failure));
          },
        );

    // Watch future entries
    _futureSubscription = _logEntryRepo
        .watchUpcomingEntriesWithContext()
        .listen(
          (entries) {
            debugPrint(
              'TimelineDataCubit: Received ${entries.length} upcoming entries',
            );
            _rawFutureEntries = entries;
            _invalidateAllCaches();
            _processAndEmit();
          },
          onError: (e) {
            debugPrint(
              'TimelineDataCubit: Error in upcoming entries stream: $e',
            );
            emit(state.copyWith(error: e, status: UiFlowStatus.failure));
          },
        );
  }

  void _subscribeToTemplates() {
    _templatesSubscription?.cancel();
    _templatesSubscription = _templateQueryDao
        .watch(isArchived: false)
        .listen((templates) {
          debugPrint(
            'TimelineDataCubit: Received ${templates.length} templates',
          );
          emit(state.copyWith(availableTemplates: templates));
          _processAndEmit(); // Re-process entries in case any were hidden due to missing templates
        });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public Filter/Sort Methods
  // ─────────────────────────────────────────────────────────────────────────

  void setTemplateFilter(String? templateId) {
    final newFilters = state.filters.copyWith(templateId: templateId);
    emit(state.copyWith(filters: newFilters));
    _invalidateTemplateCache();
    _processAndEmit();
  }

  void setTimeRange(TimelineTimeRange range, {DateTime? start, DateTime? end}) {
    final newFilters = state.filters.copyWith(
      timeRange: range,
      customStartDate: range == TimelineTimeRange.custom ? start : null,
      customEndDate: range == TimelineTimeRange.custom ? end : null,
    );
    emit(state.copyWith(filters: newFilters));
    _invalidateDateCache();
    _processAndEmit();
  }

  void setPastSort({TimelineSortType? type, bool? ascending}) {
    final newSort = state.pastSort.copyWith(
      type: type ?? state.pastSort.type,
      ascending: ascending ?? state.pastSort.ascending,
    );
    emit(state.copyWith(pastSort: newSort));
    _processAndEmit();
  }

  void setFutureSort({TimelineSortType? type, bool? ascending}) {
    final newSort = state.futureSort.copyWith(
      type: type ?? state.futureSort.type,
      ascending: ascending ?? state.futureSort.ascending,
    );
    emit(state.copyWith(futureSort: newSort));
    _processAndEmit();
  }

  void togglePastSort() {
    setPastSort(ascending: !state.pastSort.ascending);
  }

  void toggleFutureSort() {
    setFutureSort(ascending: !state.futureSort.ascending);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cache Management
  // ─────────────────────────────────────────────────────────────────────────

  void _invalidateAllCaches() {
    _templateFilterCache.clear();
    _dateFilterCache.clear();
  }

  void _invalidateTemplateCache() {
    _templateFilterCache.clear();
    _dateFilterCache.clear(); // Date cache depends on template filter
  }

  void _invalidateDateCache() {
    _dateFilterCache.clear();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Data Processing Pipeline
  // ─────────────────────────────────────────────────────────────────────────

  void _processAndEmit() {
    final processedPast = _processEntries(_rawPastEntries, state.pastSort);
    final processedFuture = _processEntries(
      _rawFutureEntries,
      state.futureSort,
    );

    final pastItems = _flattenToTimelineItems(processedPast);
    final futureItems = _flattenToTimelineItems(processedFuture);

    emit(
      state.copyWith(
        pastItems: pastItems,
        futureItems: futureItems,
        totalPastCount: processedPast.length,
        totalFutureCount: processedFuture.length,
        status: UiFlowStatus.success,
        lastOperation: TimelineDataOperation.load,
      ),
    );
  }

  List<LogEntryWithContext> _processEntries(
    List<LogEntryWithContext> rawEntries,
    TimelineSort sort,
  ) {
    // Step 1: Template filtering (cached)
    final templateFiltered = _applyTemplateFilter(rawEntries);

    // Step 2: Date filtering (cached)
    final dateFiltered = _applyDateFilter(templateFiltered);

    // Step 3: Sorting (not cached - it's fast)
    final sorted = _applySorting(dateFiltered, sort);

    return sorted;
  }

  List<LogEntryWithContext> _applyTemplateFilter(
    List<LogEntryWithContext> entries,
  ) {
    final templateId = state.filters.templateId;
    if (templateId == null) return entries;

    final cacheKey = 'template_$templateId';
    if (_templateFilterCache.containsKey(cacheKey)) {
      return _templateFilterCache[cacheKey]!;
    }

    final filtered = entries
        .where((e) => e.entry.templateId == templateId)
        .toList();

    _templateFilterCache[cacheKey] = filtered;
    return filtered;
  }

  List<LogEntryWithContext> _applyDateFilter(
    List<LogEntryWithContext> entries,
  ) {
    if (state.filters.timeRange == TimelineTimeRange.all) return entries;

    final cacheKey = _buildDateCacheKey();
    if (_dateFilterCache.containsKey(cacheKey)) {
      return _dateFilterCache[cacheKey]!;
    }

    final now = DateTime.now();
    final filtered = entries.where((e) {
      final date = e.entry.occurredAt ?? e.entry.scheduledFor;
      return _isInTimeRange(date, now);
    }).toList();

    _dateFilterCache[cacheKey] = filtered;
    return filtered;
  }

  String _buildDateCacheKey() {
    final filters = state.filters;
    return 'date_${filters.timeRange}_${filters.customStartDate}_${filters.customEndDate}';
  }

  bool _isInTimeRange(DateTime? date, DateTime now) {
    if (date == null) return false;

    switch (state.filters.timeRange) {
      case TimelineTimeRange.all:
        return true;
      case TimelineTimeRange.today:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case TimelineTimeRange.week:
        final diff = date.difference(now).inDays.abs();
        return diff < 7;
      case TimelineTimeRange.month:
        return date.year == now.year && date.month == now.month;
      case TimelineTimeRange.custom:
        final start = state.filters.customStartDate;
        final end = state.filters.customEndDate;
        if (start != null && date.isBefore(start)) return false;
        if (end != null && date.isAfter(end.add(const Duration(days: 1))))
          return false;
        return true;
    }
  }

  List<LogEntryWithContext> _applySorting(
    List<LogEntryWithContext> entries,
    TimelineSort sort,
  ) {
    final sorted = List<LogEntryWithContext>.from(entries);

    sorted.sort((a, b) {
      int cmp;

      if (sort.type == TimelineSortType.template) {
        cmp = a.template.name.compareTo(b.template.name);
        if (cmp != 0) return sort.ascending ? cmp : -cmp;
      }

      // Secondary/Default sort by date
      final dateA = a.entry.occurredAt ?? a.entry.scheduledFor;
      final dateB = b.entry.occurredAt ?? b.entry.scheduledFor;

      if (dateA == null && dateB == null) {
        cmp = 0;
      } else if (dateA == null) {
        cmp = 1;
      } else if (dateB == null) {
        cmp = -1;
      } else {
        cmp = dateA.compareTo(dateB);
      }

      return sort.ascending ? cmp : -cmp;
    });

    return sorted;
  }

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
