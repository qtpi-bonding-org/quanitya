import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/entitlement_repository.dart';
import 'paid_account_state.dart';

/// Reactive wrapper around EntitlementRepository.hasEverPurchased.
///
/// Used by UI to gate entitlement display. All persistence is in
/// EntitlementRepository. Self-hydrates in constructor.
@lazySingleton
class PaidAccountCubit extends QuanityaCubit<PaidAccountState> {
  final EntitlementRepository _repo;

  PaidAccountCubit(this._repo) : super(const PaidAccountState()) {
    _hydrate();
  }

  bool get hasPurchased => state.hasPurchased;

  Future<void> _hydrate() async {
    final value = await _repo.hasEverPurchased();
    emit(state.copyWith(
      hasPurchased: value,
      status: UiFlowStatus.success,
      lastOperation: PaidAccountOperation.load,
    ));
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
