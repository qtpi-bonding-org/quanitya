import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../data/dao/log_entry_query_dao.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';

part 'timeline_data_state.freezed.dart';

enum TimelineSortType { date, template }
enum TimelineTimeRange { all, today, week, month, custom }
enum TimelineDataOperation { load, filter, sort }

/// Represents a flattened timeline item for optimized rendering
@freezed
class TimelineItem with _$TimelineItem {
  const factory TimelineItem.entry({
    required LogEntryWithContext entryWithContext,
    required bool isFirst,
    required bool isLast,
    required bool showTimeOnly,
    // Pre-computed values for performance
    required String timeString,
    required String dateString,
    required String dataPreview,
    required Widget iconWidget,
    required Color accentColor,
  }) = TimelineEntryItem;
  
  const factory TimelineItem.dateDivider({
    required String dateKey,
    required bool isFirst,
    required String formattedDate, // Pre-computed date display
  }) = TimelineDateDivider;
}

/// Filter configuration for timeline data
@freezed
class TimelineFilters with _$TimelineFilters {
  const factory TimelineFilters({
    @Default(TimelineTimeRange.all) TimelineTimeRange timeRange,
    String? templateId,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) = _TimelineFilters;
}

/// Sort configuration for timeline data
@freezed
class TimelineSort with _$TimelineSort {
  const factory TimelineSort({
    @Default(TimelineSortType.date) TimelineSortType type,
    @Default(false) bool ascending, // Default: newest first for past
  }) = _TimelineSort;
}

@freezed
class TimelineDataState
    with _$TimelineDataState, UiFlowStateMixin
    implements IUiFlowState {
  const TimelineDataState._();

  const factory TimelineDataState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TimelineDataOperation? lastOperation,
    
    // Processed data ready for UI
    @Default([]) List<TimelineItem> pastItems,
    @Default([]) List<TimelineItem> futureItems,
    
    // Filter and sort state
    @Default(TimelineFilters()) TimelineFilters filters,
    @Default(TimelineSort()) TimelineSort pastSort,
    @Default(TimelineSort(ascending: true)) TimelineSort futureSort, // Soonest first
    
    // Available templates for filter picker
    @Default([]) List<TrackerTemplateModel> availableTemplates,
    
    // Metadata
    @Default(0) int totalPastCount,
    @Default(0) int totalFutureCount,
  }) = _TimelineDataState;
}