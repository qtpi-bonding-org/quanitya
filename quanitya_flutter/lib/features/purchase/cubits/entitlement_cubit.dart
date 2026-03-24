import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/db/app_database.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/i_entitlement_service.dart';
import 'entitlement_state.dart';

@lazySingleton
class EntitlementCubit extends QuanityaCubit<EntitlementState> {
  final IEntitlementService _entitlementService;
  final AppDatabase _db;

  EntitlementCubit(this._entitlementService, this._db)
      : super(const EntitlementState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await loadEntitlements();
      await checkSyncAccess();
      await loadStorageUsage();
      debugPrint('EntitlementCubit: Initialization complete');
    } catch (e) {
      debugPrint('EntitlementCubit: Initialization failed (non-critical): $e');
    }
  }

  Future<void> loadEntitlements() async {
    await tryOperation(() async {
      final entitlements = await _entitlementService.getEntitlements();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.loadEntitlements,
        entitlements: entitlements,
      );
    }, emitLoading: true);
  }

  Future<void> checkSyncAccess() async {
    await tryOperation(() async {
      final hasAccess = await _entitlementService.hasSyncAccess();
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: EntitlementOperation.checkSyncAccess,
        hasSyncAccess: hasAccess,
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
}
