import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'hidden_visibility_state.dart';

/// Message mapper for hidden visibility toggle operations.
@injectable
class HiddenVisibilityMessageMapper
    implements IStateMessageMapper<HiddenVisibilityState> {
  @override
  MessageKey? map(HiddenVisibilityState state) {
    final operation = state.lastOperation;
    if (state.status.isSuccess && operation != null) {
      return switch (operation) {
        HiddenVisibilityOperation.toggleHidden =>
          MessageKey.info(L10nKeys.timelineHiddenToggled),
      };
    }
    return null;
  }
}
