import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../../infrastructure/purchase/i_entitlement_service.dart';
import 'entitlement_state.dart';

@injectable
class EntitlementCubit extends QuanityaCubit<EntitlementState> {
  final IEntitlementService _entitlementService;

  EntitlementCubit(this._entitlementService) : super(const EntitlementState());

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
}
