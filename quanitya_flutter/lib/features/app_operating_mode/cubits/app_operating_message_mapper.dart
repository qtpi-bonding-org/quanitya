import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'app_operating_state.dart';

/// Message mapper for app operating mode operations
@injectable
class AppOperatingMessageMapper
    implements IStateMessageMapper<AppOperatingState> {
  @override
  MessageKey? map(AppOperatingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AppOperatingOperation.testConnection =>
          MessageKey.success('app_operating.connection_tested'),
        AppOperatingOperation.switchMode =>
          MessageKey.success('app_operating.mode_switched'),
        AppOperatingOperation.configure =>
          MessageKey.success('app_operating.configured'),
        AppOperatingOperation.externalChange =>
          MessageKey.info('app_operating.mode_changed_externally'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
