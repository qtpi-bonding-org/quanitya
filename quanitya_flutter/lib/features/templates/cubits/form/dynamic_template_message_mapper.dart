import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'dynamic_template_state.dart';

/// Message mapper for dynamic template form operations
@injectable
class DynamicTemplateMessageMapper
    implements IStateMessageMapper<DynamicTemplateState> {
  @override
  MessageKey? map(DynamicTemplateState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        DynamicTemplateOperation.load => null,
        DynamicTemplateOperation.validate => null,
        DynamicTemplateOperation.submit =>
          MessageKey.success(L10nKeys.entrySubmitted),
        DynamicTemplateOperation.clear =>
          MessageKey.info(L10nKeys.templateFormCleared),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
