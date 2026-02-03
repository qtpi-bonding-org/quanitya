import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../services/pairing_service.dart';
import 'pairing_scan_state.dart';

/// Cubit for Device A (existing device) - scans QR and registers new device.
///
/// Flow:
/// 1. Scan QR code from Device B
/// 2. Parse and validate QR data (via PairingService)
/// 3. Show confirmation dialog
/// 4. On confirm: register device (via PairingService)
@injectable
class PairingScanCubit extends QuanityaCubit<PairingScanState> {
  final IPairingService _pairingService;

  PairingScanCubit(this._pairingService) : super(const PairingScanState());

  /// Start scanning mode
  void startScanning() {
    emit(state.copyWith(scanStatus: ScanStatus.scanning));
  }

  /// Process scanned QR code
  Future<void> processQrCode(String qrJson) async {
    await tryOperation(() async {
      final scannedData = await _pairingService.parseQrCode(qrJson);

      debugPrint('PairingScanCubit: QR parsed, device label: ${scannedData.label}');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PairingScanOperation.scanQr,
        pendingDevice: PendingDevice(
          label: scannedData.label,
          signingKeyHex: scannedData.signingKeyHex,
          encryptionPublicKey: scannedData.encryptionPublicKey,
        ),
        scanStatus: ScanStatus.confirmationRequired,
      );
    }, emitLoading: true);
  }

  /// Confirm and register the new device
  Future<void> confirmAddDevice() async {
    final pending = state.pendingDevice;
    if (pending == null) return;

    emit(state.copyWith(scanStatus: ScanStatus.registering));

    await tryOperation(() async {
      await _pairingService.registerDevice(
        signingKeyHex: pending.signingKeyHex,
        encryptionPublicKey: pending.encryptionPublicKey,
        label: pending.label,
      );

      debugPrint('PairingScanCubit: Device registered successfully!');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PairingScanOperation.registerDevice,
        scanStatus: ScanStatus.success,
        pendingDevice: null,
      );
    }, emitLoading: false);
  }

  /// Cancel the pending device addition
  void cancelAddDevice() {
    emit(state.copyWith(
      pendingDevice: null,
      scanStatus: ScanStatus.scanning,
    ));
  }

  /// Reset to initial state
  void reset() {
    emit(const PairingScanState());
  }
}
