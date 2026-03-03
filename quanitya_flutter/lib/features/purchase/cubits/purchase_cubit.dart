import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/i_purchase_service.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import 'purchase_state.dart';

@injectable
class PurchaseCubit extends QuanityaCubit<PurchaseState> {
  final IPurchaseService _purchaseService;

  PurchaseCubit(this._purchaseService) : super(const PurchaseState());

  Future<void> loadProducts() async {
    await tryOperation(() async {
      final products = await _purchaseService.getProducts();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.loadProducts,
        products: products,
      );
    }, emitLoading: true);
  }

  Future<void> purchase(PurchaseRequest request) async {
    await tryOperation(() async {
      final result = await _purchaseService.purchase(request);
      analytics?.trackPurchaseCompleted(productId: request.productId);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PurchaseOperation.purchase,
        lastValidation: result,
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
