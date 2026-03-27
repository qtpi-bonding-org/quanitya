import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../models/pairing_qr_data.dart';

part 'pairing_qr_state.freezed.dart';

/// Operations for Device B (showing QR, polling)
enum PairingQrOperation {
  generateQr,
  pollSuccess,
}

/// Status of the pairing process for Device B
enum PairingStatus {
  /// Initial state - no QR generated yet
  idle,
  
  /// QR code generated, waiting for Device A to scan
  waitingForScan,
  
  /// Device A scanned and registered us, completing pairing
  completing,
  
  /// Pairing completed successfully
  success,
}

@freezed
abstract class PairingQrState with _$PairingQrState, UiFlowStateMixin implements IUiFlowState {
  const PairingQrState._();

  const factory PairingQrState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    PairingQrOperation? lastOperation,
    
    /// QR data to display (contains public key + label)
    PairingQrData? qrData,
    
    /// Current pairing status
    @Default(PairingStatus.idle) PairingStatus pairingStatus,
    
    /// Device label entered by user
    @Default('') String deviceLabel,
  }) = _PairingQrState;

  /// Whether QR code is ready to display
  bool get hasQrData => qrData != null;
  
  /// Whether we're actively polling for registration
  bool get isPolling => pairingStatus == PairingStatus.waitingForScan;
}
