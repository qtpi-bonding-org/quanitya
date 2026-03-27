import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../infrastructure/config/debug_log.dart';

import '../../../data/db/app_database.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/entitlement_repository.dart';
import '../../../infrastructure/purchase/i_entitlement_service.dart';
import 'entitlement_state.dart';

const _tag = 'features/purchase/cubits/entitlement_cubit';

@lazySingleton
class EntitlementCubit extends QuanityaCubit<EntitlementState> {
  final IEntitlementService _entitlementService;
  final EntitlementRepository _repo;
  final AppDatabase _db;

  DateTime? _lastRefresh;
  bool _isRefreshing = false;

  EntitlementCubit(this._entitlementService, this._repo, this._db)
      : super(const EntitlementState()) {
    _initialize();
  }

  bool get hasPurchased => state.hasPurchased;

  Future<void> _initialize() => tryOperation(() async {
    final purchased = await _repo.hasEverPurchased();
    emit(state.copyWith(hasPurchased: purchased));

    // Always try to fetch entitlements from server, even if local cache
    // says "never purchased". Handles app reinstall where SecurePreferences
    // is wiped but the server still has the user's entitlements.
    await loadEntitlements();

    // If server returned entitlements but local flag was wiped, fix it.
    if (!purchased && state.entitlements.isNotEmpty) {
      await _repo.markPurchased();
      emit(state.copyWith(hasPurchased: true));
    }

    if (state.hasPurchased) {
      await loadStorageUsage();
    }
    Log.d(_tag, 'EntitlementCubit: Initialization complete (hasPurchased=${state.hasPurchased})');
    return state;
  }, emitLoading: false);

  Future<void> loadEntitlements() async {
    await tryOperation(() async {
      final entitlements = await _entitlementService.getEntitlements();
      final purchased = await _repo.hasEverPurchased();
      final hasSyncAccess = await _entitlementService.hasSyncAccess();
      final hasLlmAccess = await _entitlementService.hasLlmAccess();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.loadEntitlements,
        entitlements: entitlements,
        hasPurchased: purchased,
        hasSyncAccess: hasSyncAccess,
        hasLlmAccess: hasLlmAccess,
      );
    }, emitLoading: true);
  }

  /// Loads storage usage from local encrypted entries.
  /// Multiplies by 4 to estimate server-side PostgreSQL cost
  /// (PowerSync oplog, indexes, row overhead, WAL).
  Future<void> loadStorageUsage() async {
    await tryOperation(() async {
      final result = await _db.customSelect(
        'SELECT '
        'COUNT(*) AS cnt, '
        'COALESCE(SUM(LENGTH(encrypted_data)), 0) AS total_bytes '
        'FROM encrypted_entries',
      ).getSingle();

      final count = result.read<int>('cnt');
      final rawBytes = result.read<int>('total_bytes');

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.loadStorageUsage,
        entryCount: count,
        storageBytes: rawBytes * 4, // ×4 for PostgreSQL + PowerSync overhead
      );
    }, emitLoading: false);
  }

  Future<void> markPurchased() => tryOperation(() async {
    if (state.hasPurchased) return state;
    await _repo.markPurchased();
    return state.copyWith(
      hasPurchased: true,
      status: UiFlowStatus.success,
      lastOperation: EntitlementOperation.markPurchased,
    );
  });

  Future<void> reset() => tryOperation(() async {
    await _repo.clear();
    return state.copyWith(
      hasPurchased: false,
      entitlements: [],
      hasSyncAccess: false,
      storageBytes: null,
      entryCount: null,
      status: UiFlowStatus.success,
      lastOperation: EntitlementOperation.reset,
    );
  });

  /// Refresh entitlements from server and re-check sync access.
  ///
  /// Called on app resume and by the reactive sync listener.
  /// No-op if the user has never purchased or if refreshed within the last 60s
  /// (debounce to avoid spamming server on rapid app switches).
  Future<void> refreshIfStale() async {
    if (!state.hasPurchased || _isRefreshing) return;

    final now = DateTime.now();
    final lastRefresh = _lastRefresh;
    if (lastRefresh != null && now.difference(lastRefresh).inSeconds < 60) {
      return;
    }

    _isRefreshing = true;
    try {
      await tryOperation(() async {
        final entitlements = await _entitlementService.getEntitlements();
        final hasSyncAccess = await _entitlementService.hasSyncAccess();
        final hasLlmAccess = await _entitlementService.hasLlmAccess();
        _lastRefresh = now;
        return state.copyWith(
          status: UiFlowStatus.success,
          lastOperation: EntitlementOperation.refreshIfStale,
          entitlements: entitlements,
          hasSyncAccess: hasSyncAccess,
          hasLlmAccess: hasLlmAccess,
        );
      }, emitLoading: false);
    } finally {
      _isRefreshing = false;
    }
  }
}
