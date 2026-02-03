import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'dynamic_template_state.dart';

/// Message mapper for dynamic template form operations
@injectable
class DynamicTemplateMessageMapper
    implements IStateMessageMapper<DynamicTemplateState> {
  @override
  MessageKey? map(DynamicTemplateState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        DynamicTemplateOperation.load =>
          MessageKey.info('template.form_loaded'),
        DynamicTemplateOperation.validate =>
          MessageKey.success('template.form_validated'),
        DynamicTemplateOperation.submit =>
          MessageKey.success('entry.submitted'),
        DynamicTemplateOperation.clear =>
          MessageKey.info('template.form_cleared'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
