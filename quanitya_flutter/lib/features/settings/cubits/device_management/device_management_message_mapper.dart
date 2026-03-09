import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'device_management_state.dart';

@injectable
class DeviceManagementMessageMapper implements IStateMessageMapper<DeviceManagementState> {
  @override
  MessageKey? map(DeviceManagementState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        DeviceManagementOperation.load => null, // No toast for load
        DeviceManagementOperation.revoke => MessageKey.success(L10nKeys.settingsDevicesRevoked),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
