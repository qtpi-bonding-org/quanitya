import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'health_sync_service.dart';
import 'health_sync_state.dart';

@injectable
class HealthSyncCubit extends QuanityaCubit<HealthSyncState> {
  final HealthSyncService _syncService;

  HealthSyncCubit(this._syncService) : super(const HealthSyncState());

  Future<void> requestPermissions(List<HealthDataType> types) async {
    await tryOperation(() async {
      final granted = await _syncService.requestPermissions(types);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: HealthSyncOperation.requestPermissions,
        permissionsGranted: granted,
      );
    }, emitLoading: true);
  }

  Future<void> sync(List<HealthDataType> types, {DateTime? since}) async {
    await tryOperation(() async {
      final count = await _syncService.sync(types, since: since);
      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: HealthSyncOperation.sync,
        lastImportCount: count,
      );
    }, emitLoading: true);
  }
}
