import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

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
        TemplateListOperation.archive => MessageKey.success(L10nKeys.templateArchived),
        TemplateListOperation.delete => MessageKey.success(L10nKeys.templateDeleted),
        TemplateListOperation.instantLog => MessageKey.success(L10nKeys.logEntrySaved),
        TemplateListOperation.hide => MessageKey.success(L10nKeys.templateHidden),
        TemplateListOperation.unhide => MessageKey.success(L10nKeys.templateUnhidden),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
