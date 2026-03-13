import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'llm_provider_state.dart';

@injectable
class LlmProviderMessageMapper
    implements IStateMessageMapper<LlmProviderState> {
  @override
  MessageKey? map(LlmProviderState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        LlmProviderOperation.load => null,
        LlmProviderOperation.save =>
          MessageKey.success(L10nKeys.llmProviderSaved),
        LlmProviderOperation.delete =>
          MessageKey.success(L10nKeys.llmProviderDeleted),
        LlmProviderOperation.testConnection =>
          MessageKey.success(L10nKeys.llmProviderConnectionSuccess),
        LlmProviderOperation.fetchModels => null,
      };
    }
    return null;
  }
}
