import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

part 'entitlement_state.freezed.dart';

/// Operations tracked by the EntitlementCubit.
enum EntitlementOperation { loadEntitlements, checkSyncAccess }

@freezed
class EntitlementState with _$EntitlementState, UiFlowStateMixin implements IUiFlowState {
  const EntitlementState._();

  const factory EntitlementState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    EntitlementOperation? lastOperation,
    @Default([]) List<AccountEntitlement> entitlements,
    @Default(false) bool hasSyncAccess,
  }) = _EntitlementState;
}
