import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../infrastructure/purchase/entitlement_repository.dart';

/// Thin reactive wrapper around EntitlementRepository.hasEverPurchased.
///
/// Exists only so UI can use BlocBuilder<PaidAccountCubit, bool> for
/// reactive show/hide of entitlement UI. All persistence is in
/// EntitlementRepository.
@lazySingleton
class PaidAccountCubit extends Cubit<bool> {
  final EntitlementRepository _repo;

  PaidAccountCubit(this._repo) : super(false) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final value = await _repo.hasEverPurchased();
    emit(value);
  }

  bool get hasPurchased => state;

  Future<void> markPurchased() async {
    if (state) return;
    await _repo.markPurchased();
    emit(true);
  }

  Future<void> reset() async {
    await _repo.clear();
    emit(false);
  }
}
