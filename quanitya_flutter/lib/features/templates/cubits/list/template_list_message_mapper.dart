import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'template_list_state.dart';

/// Message mapper for template list operations
@injectable
class TemplateListMessageMapper
    implements IStateMessageMapper<TemplateListState> {
  @override
  MessageKey? map(TemplateListState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemplateListOperation.load => null, // Silent load
        TemplateListOperation.archive => MessageKey.success('template.archived'),
        TemplateListOperation.delete => MessageKey.success('template.deleted'),
        TemplateListOperation.instantLog => MessageKey.success('log_entry.saved'),
        TemplateListOperation.hide => MessageKey.success('template.hidden'),
        TemplateListOperation.unhide => MessageKey.success('template.unhidden'),
        TemplateListOperation.toggleHiddenView => null, // Silent toggle
      };
    }
    return null; // Use global exception mapping for errors
  }
}
