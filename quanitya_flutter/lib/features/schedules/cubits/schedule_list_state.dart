import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../logic/schedules/models/schedule.dart';
import '../../../logic/templates/models/shared/tracker_template.dart';
import '../../../logic/templates/models/shared/template_aesthetics.dart';

part 'schedule_list_state.freezed.dart';

/// Schedule with its associated template and aesthetics for display
class ScheduleWithContext {
  final ScheduleModel schedule;
  final TrackerTemplateModel template;
  final TemplateAestheticsModel? aesthetics;

  const ScheduleWithContext({
    required this.schedule,
    required this.template,
    this.aesthetics,
  });
}

enum ScheduleListOperation { load, create, pause, resume, delete, update }

@freezed
abstract class ScheduleListState
    with _$ScheduleListState, UiFlowStateMixin
    implements IUiFlowState {
  const ScheduleListState._();

  const factory ScheduleListState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    ScheduleListOperation? lastOperation,
    @Default([]) List<ScheduleWithContext> schedules,
  }) = _ScheduleListState;
}
