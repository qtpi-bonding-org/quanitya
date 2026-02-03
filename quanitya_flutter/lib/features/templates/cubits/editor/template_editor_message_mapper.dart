import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'template_editor_state.dart';

/// Message mapper for template editor operations
@injectable
class TemplateEditorMessageMapper
    implements IStateMessageMapper<TemplateEditorState> {
  @override
  MessageKey? map(TemplateEditorState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateEditorOperation.load => MessageKey.info('template.loaded'),
        TemplateEditorOperation.updateBasicInfo =>
          MessageKey.success('template.info_updated'),
        TemplateEditorOperation.addField =>
          MessageKey.success('template.field_added'),
        TemplateEditorOperation.updateField =>
          MessageKey.success('template.field_updated'),
        TemplateEditorOperation.removeField =>
          MessageKey.success('template.field_removed'),
        TemplateEditorOperation.reorderFields =>
          MessageKey.success('template.fields_reordered'),
        TemplateEditorOperation.updateAesthetics =>
          MessageKey.success('template.aesthetics_updated'),
        TemplateEditorOperation.updateSchedule =>
          MessageKey.success('template.schedule_updated'),
        TemplateEditorOperation.save => MessageKey.success('template.saved'),
        TemplateEditorOperation.discard =>
          MessageKey.info('template.discarded'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
