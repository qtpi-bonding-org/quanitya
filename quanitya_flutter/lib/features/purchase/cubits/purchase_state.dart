import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show RailCatalogEntry;

import '../../../infrastructure/purchase/purchase_models.dart';

part 'purchase_state.freezed.dart';

/// Operations tracked by the PurchaseCubit.
enum PurchaseOperation { loadProducts, purchase, recoverPurchases, loadRailCatalog }

@freezed
class PurchaseState with _$PurchaseState, UiFlowStateMixin implements IUiFlowState {
  const PurchaseState._();

  const factory PurchaseState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    PurchaseOperation? lastOperation,
    @Default([]) List<PurchaseProduct> products,
    @Default([]) List<RailCatalogEntry> railCatalog,
  }) = _PurchaseState;
}
