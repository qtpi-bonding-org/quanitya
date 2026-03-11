import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'purchase_state.dart';

@injectable
class PurchaseMessageMapper implements IStateMessageMapper<PurchaseState> {
  @override
  MessageKey? map(PurchaseState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PurchaseOperation.loadProducts => null,
        PurchaseOperation.purchase => MessageKey.success(L10nKeys.purchaseSuccessful),
        PurchaseOperation.recoverPurchases => MessageKey.success(L10nKeys.restorePurchasesSuccess),
      };
    }
    return null;
  }
}
