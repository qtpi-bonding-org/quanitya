import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../logic/templates/services/sharing/template_export_service.dart';

part 'template_sharing_export_state.freezed.dart';

/// Operations for template sharing export
enum TemplateSharingExportOperation {
  export,
  loadScripts,
}

/// Result of a share sheet interaction
enum TemplateShareResult {
  success,
  dismissed,
  unavailable,
}

@freezed
class TemplateSharingExportState
    with _$TemplateSharingExportState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateSharingExportState._();

  const factory TemplateSharingExportState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateSharingExportOperation? lastOperation,
    @Default([]) List<AnalysisScriptInfo> availableScripts,
    TemplateShareResult? shareResult,
    String? exportedJson,
  }) = _TemplateSharingExportState;
}
