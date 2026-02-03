import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../features/templates/cubits/editor/template_editor_state.dart';

/// Message mapper for template editor operations
@injectable
class TemplateEditorMessageMapper
    implements IStateMessageMapper<TemplateEditorState> {
  @override
  MessageKey? map(TemplateEditorState state) {
    final operation = state.lastOperation;
    if (state.status.isSuccess && operation != null) {
      return switch (operation) {
        TemplateEditorOperation.save => MessageKey.success('template.saved'),
        TemplateEditorOperation.load => MessageKey.info('template.loaded'),
        TemplateEditorOperation.addField => MessageKey.success(
          'template.field_added',
        ),
        TemplateEditorOperation.removeField => MessageKey.success(
          'template.field_removed',
        ),
        TemplateEditorOperation.discard => MessageKey.info(
          'template.discarded',
        ),
        _ => null, // No message for other operations
      };
    }

    return null; // Use global exception mapping for errors
  }
}
