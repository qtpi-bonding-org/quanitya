import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../cubits/app_operating_state.dart';

@injectable
class AppOperatingMessageMapper implements IStateMessageMapper<AppOperatingState> {
  @override
  MessageKey? map(AppOperatingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AppOperatingOperation.switchMode => MessageKey.success('app.operating.mode.switched'),
        AppOperatingOperation.testConnection => state.isConnected 
          ? MessageKey.success('app.operating.connection.success')
          : MessageKey.error('app.operating.connection.failed'),
        AppOperatingOperation.configure => MessageKey.success('app.operating.configured'),
        AppOperatingOperation.externalChange => null, // No message for external changes
      };
    }
    return null; // Use global exception mapping for errors
  }
}