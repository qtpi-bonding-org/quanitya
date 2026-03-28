import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/auth/auth_service.dart';
import 'account_info_state.dart';

@lazySingleton
class AccountInfoCubit extends QuanityaCubit<AccountInfoState> {
  final AuthService _authService;

  AccountInfoCubit(this._authService) : super(const AccountInfoState());

  /// Load account info. Safe to call multiple times — only emits if key found.
  Future<void> loadAccountInfo() async {
    // Skip if already loaded
    if (state.accountPublicKeyHex != null) return;

    await tryOperation(() async {
      final accountKeyHex = await _authService.getAccountPublicKeyHex();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: AccountInfoOperation.load,
        accountPublicKeyHex: accountKeyHex,
      );
    }, emitLoading: false);
  }
}
