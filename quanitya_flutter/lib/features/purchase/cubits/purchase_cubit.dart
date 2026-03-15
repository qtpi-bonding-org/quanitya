import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/auth/auth_service.dart';
import '../../../infrastructure/purchase/i_purchase_service.dart';
import '../../../infrastructure/purchase/purchase_models.dart';
import '../../../features/app_operating_mode/models/app_operating_mode.dart';
import 'purchase_state.dart';

@injectable
class PurchaseCubit extends QuanityaCubit<PurchaseState> {
  final IPurchaseService _purchaseService;
  final AuthService _authService;
  Completer<void>? _registrationLock;

  PurchaseCubit(this._purchaseService, this._authService) : super(const PurchaseState());

  Future<void> _ensureRegistered() async {
    if (await _authService.isRegisteredWithServer) return;
    if (_registrationLock != null) {
      await _registrationLock!.future;
      return;
    }
    _registrationLock = Completer<void>();
    try {
      await _authService.registerAccountWithServer(deviceLabel: 'auto');
      _registrationLock!.complete();
    } catch (e) {
      _registrationLock!.completeError(e);
      rethrow;
    } finally {
      _registrationLock = null;
    }
  }

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

  Future<void> purchase(PurchaseRequest request, {required AppOperatingMode mode}) async {
    await tryOperation(() async {
      await _ensureRegistered();
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
