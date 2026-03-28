import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../infrastructure/auth/account_service.dart';
import '../../../../infrastructure/auth/auth_service.dart' show AuthException;
import '../../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../../infrastructure/device/device_info_service.dart';
import 'device_management_state.dart';

/// Cubit for managing registered devices
///
/// Provides:
/// - List all devices registered to the account
/// - Identify current device
/// - Revoke other devices
/// - Manage cross-device key (iCloud / Google Block Store)
/// - Check/clear local keys (for recovery flow)
@injectable
class DeviceManagementCubit extends QuanityaCubit<DeviceManagementState> {
  final AccountService _accountService;
  final ICryptoKeyRepository _keyRepository;
  final DeviceInfoService _deviceInfoService;

  DeviceManagementCubit(this._accountService, this._keyRepository, this._deviceInfoService)
      : super(const DeviceManagementState());

  /// Load all devices for the current account
  Future<void> loadDevices() async {
    await tryOperation(() async {
      // Get current device's public key to identify it in the list
      final currentPublicKey = await _accountService.getCurrentDevicePublicKeyHex();
      
      // Fetch devices from server
      final devices = await _accountService.listDevices();

      return state.copyWith(
        status: UiFlowStatus.success,
        devices: devices,
        currentDevicePublicKey: currentPublicKey,
        lastOperation: DeviceManagementOperation.load,
      );
    }, emitLoading: true);
  }

  /// Revoke a device by ID
  /// 
  /// Cannot revoke the current device - user must sign out instead.
  Future<void> revokeDevice(UuidValue deviceId, {required String ultimateKeyJwk}) async {
    // Check if trying to revoke current device
    final device = state.devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw const AuthException('Device not found'),
    );

    if (state.isCurrentDevice(device)) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: const AuthException('Cannot revoke current device. Sign out instead.'),
      ));
      return;
    }

    await tryOperation(() async {
      emit(state.copyWith(revokingDeviceId: deviceId));

      await _accountService.revokeDevice(deviceId, ultimateKeyJwk: ultimateKeyJwk);

      // If revoking the cross-device key, also delete from platform storage
      if (_keyRepository.isCrossDeviceStorageAvailable &&
          device.label == _keyRepository.crossDeviceLabel) {
        await _keyRepository.deleteCrossDeviceKey();
      }

      // Reload devices to get updated list
      final devices = await _accountService.listDevices();

      analytics?.trackDeviceRevoked();

      return state.copyWith(
        status: UiFlowStatus.success,
        devices: devices,
        revokingDeviceId: null,
        lastOperation: DeviceManagementOperation.revoke,
      );
    }, emitLoading: false); // Don't show full loading, just the revoking indicator
  }

  /// Recreate cross-device key (Flow D — re-enable cross-device sync)
  ///
  /// Generates a new cross-device key, registers with server,
  /// and stores in platform storage.
  Future<void> recreateCrossDeviceKey() async {
    await tryOperation(() async {
      await _accountService.recreateCrossDeviceKey();

      // Reload devices to show new cross-device entry
      final devices = await _accountService.listDevices();

      analytics?.trackDevicePaired();

      return state.copyWith(
        status: UiFlowStatus.success,
        devices: devices,
        lastOperation: DeviceManagementOperation.recreateCrossDevice,
      );
    }, emitLoading: true);
  }

  /// Refresh the device list
  Future<void> refresh() => loadDevices();

  /// Load local device info for the recovery flow.
  ///
  /// Populates [deviceName] and [hasExistingKeys] in state.
  Future<void> loadLocalDeviceInfo() => tryOperation(() async {
    final deviceName = await _deviceInfoService.getDeviceName();
    final hasKeys = await _keyRepository.hasExistingKeys();
    return state.copyWith(
      status: UiFlowStatus.success,
      deviceName: deviceName,
      hasExistingKeys: hasKeys,
    );
  }, emitLoading: false);

}
