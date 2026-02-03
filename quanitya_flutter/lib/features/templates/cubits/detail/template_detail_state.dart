import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../logic/schedules/models/schedule.dart';

part 'template_detail_state.freezed.dart';

enum TemplateDetailOperation { load }

@freezed
class TemplateDetailState
    with _$TemplateDetailState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateDetailState._();
  
  const factory TemplateDetailState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateDetailOperation? lastOperation,
    TemplateWithAesthetics? template,
    @Default([]) List<LogEntryModel> recentEntries,
    @Default([]) List<ScheduleModel> schedules,
  }) = _TemplateDetailState;
}
