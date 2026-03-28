import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../logic/templates/models/shared/shareable_template.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';

part 'template_sharing_import_state.freezed.dart';

/// Operations for template sharing import
enum TemplateSharingImportOperation {
  preview,
  confirmImport,
  clear,
}

@freezed
abstract class TemplateSharingImportState
    with _$TemplateSharingImportState, UiFlowStateMixin
    implements IUiFlowState {
  const TemplateSharingImportState._();

  const factory TemplateSharingImportState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemplateSharingImportOperation? lastOperation,
    String? previewUrl,
    ShareableTemplate? previewTemplate,
    TemplateWithAesthetics? importedTemplate,
  }) = _TemplateSharingImportState;
}
