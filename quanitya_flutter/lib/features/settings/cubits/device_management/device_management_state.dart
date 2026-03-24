import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:anonaccount_client/anonaccount_client.dart' show AccountDevice;

part 'device_management_state.freezed.dart';

/// Operations for device management
enum DeviceManagementOperation {
  load,
  revoke,
  recreateCrossDevice,
}

@freezed
class DeviceManagementState with _$DeviceManagementState, UiFlowStateMixin implements IUiFlowState {
  const DeviceManagementState._();

  const factory DeviceManagementState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    @Default([]) List<AccountDevice> devices,
    String? currentDevicePublicKey,
    int? revokingDeviceId,
    String? deviceName,
    @Default(false) bool hasExistingKeys,
    Object? error,
    DeviceManagementOperation? lastOperation,
  }) = _DeviceManagementState;

  /// Check if a device is the current device
  bool isCurrentDevice(AccountDevice device) =>
      currentDevicePublicKey != null && device.deviceSigningPublicKeyHex == currentDevicePublicKey;

  /// Get active (non-revoked) devices
  List<AccountDevice> get activeDevices =>
      devices.where((d) => !d.isRevoked).toList();

  /// Get revoked devices
  List<AccountDevice> get revokedDevices =>
      devices.where((d) => d.isRevoked).toList();
}
