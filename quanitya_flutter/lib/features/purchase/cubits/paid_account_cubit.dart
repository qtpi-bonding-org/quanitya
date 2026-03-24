import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/entitlement_repository.dart';
import '../../../infrastructure/purchase/i_entitlement_service.dart';
import 'paid_account_state.dart';

/// Reactive wrapper around EntitlementRepository.hasEverPurchased.
///
/// Used by UI to gate entitlement display. All persistence is in
/// EntitlementRepository. Self-initializes in constructor.
@lazySingleton
class PaidAccountCubit extends QuanityaCubit<PaidAccountState> {
  final EntitlementRepository _repo;
  final IEntitlementService _entitlementService;

  PaidAccountCubit(this._repo, this._entitlementService)
      : super(const PaidAccountState()) {
    _initialize();
  }

  bool get hasPurchased => state.hasPurchased;

  Future<void> _initialize() async {
    final value = await _repo.hasEverPurchased();
    emit(state.copyWith(
      hasPurchased: value,
      status: UiFlowStatus.success,
      lastOperation: PaidAccountOperation.load,
    ));

    if (value) {
      try {
        await _entitlementService.getEntitlements();
        debugPrint('PaidAccountCubit: Entitlement cache refreshed');
      } catch (e) {
        debugPrint(
            'PaidAccountCubit: Entitlement cache refresh failed (using stale cache): $e');
      }
    }
  }

  Future<void> markPurchased() => tryOperation(() async {
    if (state.hasPurchased) return state;
    await _repo.markPurchased();
    return state.copyWith(
      hasPurchased: true,
      status: UiFlowStatus.success,
      lastOperation: PaidAccountOperation.markPurchased,
    );
  });

  Future<void> reset() => tryOperation(() async {
    await _repo.clear();
    return state.copyWith(
      hasPurchased: false,
      status: UiFlowStatus.success,
      lastOperation: PaidAccountOperation.reset,
    );
  });
}
