import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/repositories/template_with_aesthetics_repository.dart';

part 'template_list_state.freezed.dart';

enum TemplateListOperation { load, archive, delete, instantLog, hide, unhide, toggleHiddenView }

@freezed
class TemplateListState
    with _$TemplateListState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateListState._();

  const factory TemplateListState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateListOperation? lastOperation,
    @Default([]) List<TemplateWithAesthetics> templates,
    /// Whether hidden templates are currently visible (requires auth to enable)
    @Default(false) bool showingHidden,
  }) = _TemplateListState;
}
