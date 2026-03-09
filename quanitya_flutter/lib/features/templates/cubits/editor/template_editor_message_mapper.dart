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
        TemplateEditorOperation.load => MessageKey.info(L10nKeys.templateLoaded),
        TemplateEditorOperation.updateBasicInfo =>
          MessageKey.success('template.info_updated'),
        TemplateEditorOperation.addField =>
          MessageKey.success(L10nKeys.templateFieldAdded),
        TemplateEditorOperation.updateField =>
          MessageKey.success('template.field_updated'),
        TemplateEditorOperation.removeField =>
          MessageKey.success(L10nKeys.templateFieldRemoved),
        TemplateEditorOperation.reorderFields =>
          MessageKey.success('template.fields_reordered'),
        TemplateEditorOperation.updateAesthetics =>
          MessageKey.success('template.aesthetics_updated'),
        TemplateEditorOperation.updateSchedule =>
          MessageKey.success('template.schedule_updated'),
        TemplateEditorOperation.save => MessageKey.success(L10nKeys.templateSaved),
        TemplateEditorOperation.discard =>
          MessageKey.info(L10nKeys.templateDiscarded),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
