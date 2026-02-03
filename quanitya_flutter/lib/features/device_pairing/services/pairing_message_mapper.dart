import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../infrastructure/feedback/base_state_message_mapper.dart';
import '../cubits/pairing_qr_state.dart';
import '../cubits/pairing_scan_state.dart';

/// Domain mapper for Device B (QR display) operations - success messages only
class _PairingQrDomainMapper implements IStateMessageMapper<PairingQrState> {
  @override
  MessageKey? map(PairingQrState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PairingQrOperation.generateQr => MessageKey.success('pairing.qr.generated'),
        PairingQrOperation.pollSuccess => MessageKey.success('pairing.completed'),
      };
    }
    return null;
  }
}

/// Message mapper for Device B (QR display) operations
/// Wraps domain mapper with exception mapper for error toasts
@injectable
class PairingQrMessageMapper extends BaseStateMessageMapper<PairingQrState> {
  PairingQrMessageMapper(IExceptionKeyMapper exceptionMapper)
      : super(
          exceptionMapper: exceptionMapper,
          domainMapper: _PairingQrDomainMapper(),
        );
}

/// Domain mapper for Device A (QR scan) operations - success messages only
class _PairingScanDomainMapper implements IStateMessageMapper<PairingScanState> {
  @override
  MessageKey? map(PairingScanState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PairingScanOperation.scanQr => null, // No toast for scan, show confirmation instead
        PairingScanOperation.registerDevice => MessageKey.success('pairing.device.added'),
      };
    }
    return null;
  }
}

/// Message mapper for Device A (QR scan) operations
/// Wraps domain mapper with exception mapper for error toasts
@injectable
class PairingScanMessageMapper extends BaseStateMessageMapper<PairingScanState> {
  PairingScanMessageMapper(IExceptionKeyMapper exceptionMapper)
      : super(
          exceptionMapper: exceptionMapper,
          domainMapper: _PairingScanDomainMapper(),
        );
}
