import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../infrastructure/auth/auth_service.dart';
import 'device_management_state.dart';

/// Cubit for managing registered devices
/// 
/// Provides:
/// - List all devices registered to the account
/// - Identify current device
/// - Revoke other devices
@injectable
class DeviceManagementCubit extends QuanityaCubit<DeviceManagementState> {
  final AuthService _authService;

  DeviceManagementCubit(this._authService)
      : super(const DeviceManagementState());

  /// Load all devices for the current account
  Future<void> loadDevices() async {
    await tryOperation(() async {
      // Get current device's public key to identify it in the list
      final currentPublicKey = await _authService.getCurrentDevicePublicKeyHex();
      
      // Fetch devices from server
      final devices = await _authService.listDevices();

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
  Future<void> revokeDevice(int deviceId) async {
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
      
      await _authService.revokeDevice(deviceId);

      // Reload devices to get updated list
      final devices = await _authService.listDevices();

      return state.copyWith(
        status: UiFlowStatus.success,
        devices: devices,
        revokingDeviceId: null,
        lastOperation: DeviceManagementOperation.revoke,
      );
    }, emitLoading: false); // Don't show full loading, just the revoking indicator
  }

  /// Refresh the device list
  Future<void> refresh() => loadDevices();
}
