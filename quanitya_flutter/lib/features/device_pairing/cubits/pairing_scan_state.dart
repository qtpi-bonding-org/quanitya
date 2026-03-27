import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:webcrypto/webcrypto.dart';

part 'pairing_scan_state.freezed.dart';

/// Operations for Device A (scanning QR, registering)
enum PairingScanOperation {
  scanQr,
  registerDevice,
}

/// Status of the scanning process for Device A
enum ScanStatus {
  /// Initial state - camera not started
  idle,
  
  /// Camera active, scanning for QR
  scanning,
  
  /// QR scanned, awaiting user confirmation
  confirmationRequired,
  
  /// User confirmed, registering device
  registering,
  
  /// Device registered successfully
  success,
}

/// Pending device info parsed from QR code
@freezed
abstract class PendingDevice with _$PendingDevice {
  const factory PendingDevice({
    required String label,
    required String signingKeyHex,
    required EcdhPublicKey encryptionPublicKey,
  }) = _PendingDevice;
}

@freezed
abstract class PairingScanState with _$PairingScanState, UiFlowStateMixin implements IUiFlowState {
  const PairingScanState._();

  const factory PairingScanState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    PairingScanOperation? lastOperation,
    
    /// Pending device info from scanned QR
    PendingDevice? pendingDevice,
    
    /// Current scan status
    @Default(ScanStatus.idle) ScanStatus scanStatus,
  }) = _PairingScanState;

  /// Whether we have a pending device to confirm
  bool get hasPendingDevice => pendingDevice != null;
  
  /// Whether confirmation dialog should be shown
  bool get showConfirmation => scanStatus == ScanStatus.confirmationRequired;
}
