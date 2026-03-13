import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'template_editor_state.dart';

/// Message mapper for template editor operations
@injectable
class TemplateEditorMessageMapper
    implements IStateMessageMapper<TemplateEditorState> {
  @override
  MessageKey? map(TemplateEditorState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateEditorOperation.load => null,
        TemplateEditorOperation.updateBasicInfo =>
          MessageKey.success(L10nKeys.templateInfoUpdated),
        TemplateEditorOperation.addField =>
          MessageKey.success(L10nKeys.templateFieldAdded),
        TemplateEditorOperation.updateField =>
          MessageKey.success(L10nKeys.templateFieldUpdated),
        TemplateEditorOperation.removeField =>
          MessageKey.success(L10nKeys.templateFieldRemoved),
        TemplateEditorOperation.reorderFields =>
          MessageKey.success(L10nKeys.templateFieldsReordered),
        TemplateEditorOperation.updateAesthetics =>
          MessageKey.success(L10nKeys.templateAestheticsUpdated),
        TemplateEditorOperation.updateSchedule =>
          MessageKey.success(L10nKeys.templateScheduleUpdated),
        TemplateEditorOperation.save => MessageKey.success(L10nKeys.templateSaved),
        TemplateEditorOperation.discard =>
          MessageKey.info(L10nKeys.templateDiscarded),
        TemplateEditorOperation.toggleHidden => state.template?.isHidden == true
          ? MessageKey.info(L10nKeys.templateHidden)
          : MessageKey.info(L10nKeys.templateUnhidden),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
