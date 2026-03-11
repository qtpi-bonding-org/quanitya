import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'error_box_state.dart';

@injectable
class ErrorBoxMessageMapper implements IStateMessageMapper<ErrorBoxState> {
  @override
  MessageKey? map(ErrorBoxState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        ErrorBoxOperation.sendOne =>
          MessageKey.success(L10nKeys.errorBoxSendOneSuccess),
        ErrorBoxOperation.sendAll =>
          MessageKey.success(L10nKeys.errorBoxSendAllSuccess),
        ErrorBoxOperation.markAsSent =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
        ErrorBoxOperation.markAllAsSent =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
        ErrorBoxOperation.delete =>
          MessageKey.success(L10nKeys.errorBoxDeleteSuccess),
        ErrorBoxOperation.deleteAll =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
      };
    }

    if (state.status.isFailure && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        ErrorBoxOperation.sendOne =>
          MessageKey.error(L10nKeys.errorBoxSendError),
        ErrorBoxOperation.sendAll =>
          MessageKey.error(L10nKeys.errorBoxSendError),
        _ => MessageKey.error(L10nKeys.errorBoxOperationError),
      };
    }

    return null;
  }
}
