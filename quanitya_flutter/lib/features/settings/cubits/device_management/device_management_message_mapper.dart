import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
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
        DeviceManagementOperation.recreateCrossDevice => () {
          final (key, args) = L10nKeys.createPlatformDeviceKey(
            GetIt.instance<ICryptoKeyRepository>().crossDeviceLabel,
          );
          return MessageKey.success(key, args);
        }(),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
