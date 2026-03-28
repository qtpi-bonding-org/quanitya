import 'dart:async';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../infrastructure/config/debug_log.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../services/pairing_service.dart';
import 'pairing_qr_state.dart';

const _tag = 'features/device_pairing/cubits/pairing_qr_cubit';

/// Cubit for Device B (new device) - generates QR and polls for registration.
///
/// Flow:
/// 1. User enters device label
/// 2. Generate keys and show QR (via PairingService)
/// 3. Poll server for registration
/// 4. On registration found, complete pairing (via PairingService)
@injectable
class PairingQrCubit extends QuanityaCubit<PairingQrState> {
  final IPairingService _pairingService;

  PairingQrCubit(this._pairingService) : super(const PairingQrState());

  // Temporary storage for generated keys (before pairing completes)
  KeyDuo? _pendingDeviceKey;
  StreamSubscription<String>? _registrationSubscription;

  /// Update device label
  void setDeviceLabel(String label) {
    emit(state.copyWith(deviceLabel: label));
  }

  /// Generate keys and create QR data for pairing
  Future<void> generatePairingQr() async {
    if (state.deviceLabel.trim().isEmpty) return;

    await tryOperation(() async {
      final result = await _pairingService.generatePairingQrData(
        state.deviceLabel.trim(),
      );

      // Store for later use
      _pendingDeviceKey = result.deviceKey;

      Log.d(
        _tag,
        'PairingQrCubit: QR data generated, monitoring registration...',
      );

      // Start monitoring stream
      _startMonitoring(result.signingKeyHex);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PairingQrOperation.generateQr,
        qrData: result.qrData,
        pairingStatus: PairingStatus.waitingForScan,
      );
    }, emitLoading: true);
  }

  /// Start monitoring server for registration
  void _startMonitoring(String signingKeyHex) {
    _registrationSubscription?.cancel();
    _registrationSubscription = _pairingService
        .monitorRegistration(signingKeyHex)
        .listen(
          (encryptedDataKey) {
            Log.d(
              _tag,
              'PairingQrCubit: Registration event received! Completing pairing...',
            );
            _completePairing(encryptedDataKey);
          },
          onError: (e) {
            Log.d(_tag, 'PairingQrCubit: Monitoring error: $e');
            // Ideally handle error state here, or retry
          },
        );
  }

  /// Stop monitoring
  void _stopMonitoring() {
    _registrationSubscription?.cancel();
    _registrationSubscription = null;
  }

  /// Complete pairing by decrypting SDK and storing keys
  Future<void> _completePairing(String encryptedDataKey) async {
    _stopMonitoring(); // Stop listening once we have the key
    emit(state.copyWith(pairingStatus: PairingStatus.completing));

    await tryOperation(() async {
      final deviceKey = _pendingDeviceKey;
      if (deviceKey == null) {
        throw const PairingException('Device key not available');
      }

      await _pairingService.completePairing(
        encryptedDataKey: encryptedDataKey,
        deviceKey: deviceKey,
      );

      // Clear temporary storage
      _pendingDeviceKey = null;

      Log.d(_tag, 'PairingQrCubit: Pairing completed successfully!');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PairingQrOperation.pollSuccess,
        pairingStatus: PairingStatus.success,
      );
    }, emitLoading: false);
  }

  /// Cancel pairing and clean up
  void cancelPairing() {
    _stopMonitoring();
    _pendingDeviceKey = null;
    emit(const PairingQrState());
  }

  @override
  Future<void> close() {
    _stopMonitoring();
    return super.close();
  }
}
