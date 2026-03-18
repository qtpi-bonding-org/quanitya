import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../infrastructure/permissions/permission_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'health_sync_service.dart';
import 'health_sync_state.dart';

@injectable
class HealthSyncCubit extends QuanityaCubit<HealthSyncState> {
  final HealthSyncService _syncService;
  final PermissionService _permissionService;

  HealthSyncCubit(this._syncService, this._permissionService) : super(const HealthSyncState());

  /// Hydrate the toggle state from persisted preference.
  Future<void> loadEnabled() async {
    final enabled = await _syncService.isEnabled();
    if (enabled != state.enabled) {
      emit(state.copyWith(enabled: enabled));
    }
  }

  /// Toggle health sync on/off.
  ///
  /// On: request permissions → initial sync → persist enabled.
  /// Off: persist disabled.
  Future<void> toggle(bool enabled, List<HealthDataType> types) async {
    if (!enabled) {
      await _syncService.setEnabled(false);
      emit(state.copyWith(
        enabled: false,
        status: UiFlowStatus.success,
        lastOperation: HealthSyncOperation.toggle,
      ));
      return;
    }

    await tryOperation(() async {
      await _permissionService.ensureHealth(types);
      final count = await _syncService.sync(types);
      await _syncService.setEnabled(true);
      analytics?.trackHealthSynced();
      return state.copyWith(
        enabled: true,
        status: UiFlowStatus.success,
        lastOperation: HealthSyncOperation.toggle,
        lastImportCount: count,
      );
    }, emitLoading: true);
  }
}
