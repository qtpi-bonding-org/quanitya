import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'template_generator_state.dart';

/// Message mapper for template generator operations
@injectable
class TemplateGeneratorMessageMapper
    implements IStateMessageMapper<TemplateGeneratorState> {
  @override
  MessageKey? map(TemplateGeneratorState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        GeneratorOperation.generate =>
          MessageKey.success('template.generated'),
        GeneratorOperation.save => MessageKey.success(L10nKeys.templateSaved),
        GeneratorOperation.discard => MessageKey.info(L10nKeys.templateDiscarded),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
