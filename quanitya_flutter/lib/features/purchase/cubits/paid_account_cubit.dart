import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../infrastructure/platform/secure_preferences.dart';

/// Tracks whether the user has ever made a purchase.
///
/// This is a simple persistent flag — set once on first purchase, never
/// unset (except factory reset). Used to gate entitlement UI: if the user
/// has never purchased anything, there's no reason to show balances or
/// make server calls to check entitlements.
///
/// Independent of sync mode — AI credits, consumables, and sync tiers
/// all set this flag on purchase.
@lazySingleton
class PaidAccountCubit extends Cubit<bool> {
  final SecurePreferences _prefs;

  static const String _key = 'has_ever_purchased';

  PaidAccountCubit(this._prefs) : super(false);

  /// Load the flag from secure storage. Call once at bootstrap.
  Future<void> initialize() async {
    final value = await _prefs.getBool(_key);
    emit(value == true);
    if (value == true) {
      debugPrint('PaidAccountCubit: User has purchased before');
    }
  }

  /// Whether the user has ever made a purchase.
  bool get hasPurchased => state;

  /// Mark that the user has made a purchase. Persists immediately.
  Future<void> markPurchased() async {
    if (state) return; // Already marked
    await _prefs.setBool(_key, true);
    emit(true);
    debugPrint('PaidAccountCubit: Marked as paid account');
  }

  /// Clear the flag (factory reset only).
  Future<void> reset() async {
    await _prefs.remove(_key);
    emit(false);
  }
}
