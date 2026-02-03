import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../../infrastructure/auth/auth_service.dart';
import 'recovery_key_state.dart';

@injectable
class RecoveryKeyCubit extends QuanityaCubit<RecoveryKeyState> {
  final AuthService _authService;

  RecoveryKeyCubit(this._authService) : super(const RecoveryKeyState());

  /// Validate a recovery key (JWK) format.
  ///
  /// Validates the JWK format and cryptographic integrity without
  /// performing full recovery.
  Future<void> validateRecoveryKey(String jwk) async {
    await tryOperation(() async {
      await _authService.validateRecoveryKey(jwk);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: RecoveryKeyOperation.validate,
      );
    }, emitLoading: true);
  }

  /// Recover account using the recovery key.
  ///
  /// Flow:
  /// 1. Import and validate ultimate JWK
  /// 2. Look up account on server by ultimate public key
  /// 3. Decrypt recovery blob to get symmetric key
  /// 4. Generate new device keys and register with account
  /// 5. Store keys locally
  Future<void> recoverAccount({
    required String jwk,
    required String deviceLabel,
  }) async {
    await tryOperation(() async {
      await _authService.recoverAccount(
        ultimatePrivateKey: jwk,
        deviceLabel: deviceLabel,
      );
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: RecoveryKeyOperation.recover,
      );
    }, emitLoading: true);
  }
}
