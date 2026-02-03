import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'device_management_state.dart';

@injectable
class DeviceManagementMessageMapper implements IStateMessageMapper<DeviceManagementState> {
  @override
  MessageKey? map(DeviceManagementState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        DeviceManagementOperation.load => null, // No toast for load
        DeviceManagementOperation.revoke => MessageKey.success('settings.devices.revoked'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
