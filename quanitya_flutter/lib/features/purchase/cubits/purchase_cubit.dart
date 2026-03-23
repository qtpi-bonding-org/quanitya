import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/i_purchase_service.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../features/app_syncing_mode/models/app_syncing_mode.dart';
import 'purchase_state.dart';

@injectable
class PurchaseCubit extends QuanityaCubit<PurchaseState> {
  final IPurchaseService _purchaseService;

  PurchaseCubit(this._purchaseService) : super(const PurchaseState());

  Future<void> loadProducts() async {
    emit(state.copyWith(lastOperation: PurchaseOperation.loadProducts));
    await tryOperation(() async {
      final products = await _purchaseService.getProducts();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.loadProducts,
        products: products,
      );
    }, emitLoading: true);
  }

  Future<void> purchase(PurchaseRequest request, {required AppSyncingMode mode}) async {
    await tryOperation(() async {
      await _purchaseService.purchase(request, mode: mode);
      analytics?.trackPurchaseCompleted(productId: request.productId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.purchase,
      );
    }, emitLoading: true);
  }

  Future<void> loadRailCatalog() async {
    await tryOperation(() async {
      final catalog = await _purchaseService.getRailCatalog();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.loadRailCatalog,
        railCatalog: catalog,
      );
    }, emitLoading: true);
  }

  Future<void> recoverPurchases() async {
    await tryOperation(() async {
      await _purchaseService.recoverPendingPurchases();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.recoverPurchases,
      );
    }, emitLoading: true);
  }
}
