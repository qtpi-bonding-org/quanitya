import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show AccountFeatureEntitlement;

part 'entitlement_state.freezed.dart';

/// Operations tracked by the EntitlementCubit.
enum EntitlementOperation { loadEntitlements, loadStorageUsage, markPurchased, reset, refreshIfStale }

@freezed
abstract class EntitlementState with _$EntitlementState, UiFlowStateMixin implements IUiFlowState {
  const EntitlementState._();

  const factory EntitlementState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    EntitlementOperation? lastOperation,
    @Default([]) List<AccountFeatureEntitlement> entitlements,
    @Default(false) bool hasSyncAccess,
    @Default(false) bool hasAiAccess,
    @Default(false) bool hasPurchased,
    /// Estimated storage used in bytes (encrypted blobs × 2 for oplog).
    int? storageBytes,
    /// Total encrypted entry count.
    int? entryCount,
  }) = _EntitlementState;
}
