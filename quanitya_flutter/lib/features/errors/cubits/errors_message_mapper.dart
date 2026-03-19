import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'errors_state.dart';

@injectable
class ErrorsMessageMapper implements IStateMessageMapper<ErrorsState> {
  @override
  MessageKey? map(ErrorsState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        ErrorsOperation.sendOne =>
          MessageKey.success(L10nKeys.errorBoxSendOneSuccess),
        ErrorsOperation.sendAll =>
          MessageKey.success(L10nKeys.errorBoxSendAllSuccess),
        ErrorsOperation.markAsSent =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
        ErrorsOperation.markAllAsSent =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
        ErrorsOperation.delete =>
          MessageKey.success(L10nKeys.errorBoxDeleteSuccess),
        ErrorsOperation.deleteAll =>
          MessageKey.success(L10nKeys.errorBoxClearedSuccess),
        ErrorsOperation.toggleAutoSend =>
          MessageKey.success(L10nKeys.errorBoxToggleAutoSendSuccess),
      };
    }

    if (state.status.isFailure && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        ErrorsOperation.sendOne =>
          MessageKey.error(L10nKeys.errorBoxSendError),
        ErrorsOperation.sendAll =>
          MessageKey.error(L10nKeys.errorBoxSendError),
        _ => MessageKey.error(L10nKeys.errorBoxOperationError),
      };
    }

    return null;
  }
}
