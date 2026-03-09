import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

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
        TemplateEditorOperation.save => MessageKey.success(L10nKeys.templateSaved),
        TemplateEditorOperation.load => null,
        TemplateEditorOperation.addField => MessageKey.success(
          L10nKeys.templateFieldAdded,
        ),
        TemplateEditorOperation.removeField => MessageKey.success(
          L10nKeys.templateFieldRemoved,
        ),
        TemplateEditorOperation.discard => MessageKey.info(
          L10nKeys.templateDiscarded,
        ),
        _ => null, // No message for other operations
      };
    }

    return null; // Use global exception mapping for errors
  }
}
