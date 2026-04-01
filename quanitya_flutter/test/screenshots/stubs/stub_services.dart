/// Stub implementations for screenshot golden tests.
///
/// These provide minimal no-op or empty-stream behavior so the widget tree
/// can render without a real database, network, or platform channels.
library;

import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart';
import 'package:quanitya_flutter/data/repositories/schedule_repository.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/features/account/cubits/account_info_cubit.dart';
import 'package:quanitya_flutter/features/account/cubits/account_info_state.dart';
import 'package:quanitya_flutter/features/analytics/cubits/analytics_cubit.dart';
import 'package:quanitya_flutter/features/analytics/cubits/analytics_state.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_state.dart';
import 'package:quanitya_flutter/features/errors/cubits/errors_cubit.dart';
import 'package:quanitya_flutter/features/errors/cubits/errors_state.dart';
import 'package:quanitya_flutter/features/notices/cubits/notices_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_state.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_state.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_state.dart';
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_cubit.dart';
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_state.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_repository.dart';
import 'package:quanitya_flutter/infrastructure/auth/delete_orchestrator.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_secure_storage.dart';
import 'package:quanitya_flutter/infrastructure/device/device_info_service.dart';
import 'package:quanitya_flutter/infrastructure/permissions/permission_service.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_cubit.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_state.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/log_entries/services/log_entry_service.dart';
import 'package:quanitya_flutter/logic/schedules/models/schedule.dart';
import 'package:quanitya_flutter/logic/schedules/services/schedule_service.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_state.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_state.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_state.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_state.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_state.dart';
import 'package:quanitya_flutter/features/results/cubits/results_list_cubit.dart';
import 'package:quanitya_flutter/features/results/cubits/results_list_state.dart';
import 'package:quanitya_flutter/features/visualization/cubits/visualization_cubit.dart';
import 'package:quanitya_flutter/features/visualization/cubits/visualization_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Safe noSuchMethod base — returns Future.value() for async calls
// ─────────────────────────────────────────────────────────────────────────────

/// Mixin that provides a noSuchMethod returning safe defaults.
/// Returns Future.value() for methods that return Future, Stream.empty() for
/// streams, and null for everything else.
mixin SafeNoSuchMethod {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return safe defaults based on common return types
    return Future<void>.value();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback / Loading stubs (no-op)
// ─────────────────────────────────────────────────────────────────────────────

class StubFeedbackService implements cubit_ui_flow.IFeedbackService {
  @override
  void show(cubit_ui_flow.FeedbackMessage message) {}
}

class StubLoadingService implements cubit_ui_flow.ILoadingService {
  @override
  void show() {}
  @override
  void hide() {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Secure storage stub (in-memory)
// ─────────────────────────────────────────────────────────────────────────────

class StubSecureStorage implements ISecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> storeSecureData(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> getSecureData(String key) async => _data[key];

  @override
  Future<void> deleteSecureData(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<Map<String, String>> getAllData() async => Map.from(_data);

  // Catch-all for remaining ISecureStorage methods (device keys, iCloud, etc.)
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

// ─────────────────────────────────────────────────────────────────────────────
// Data layer stubs (empty streams, using noSuchMethod for unneeded methods)
// ─────────────────────────────────────────────────────────────────────────────

class StubLogEntryRepository implements ILogEntryRepository {
  @override
  Stream<List<LogEntryModel>> watchEntriesForTemplate(String templateId) =>
      Stream.value([]);

  @override
  Stream<List<LogEntryModel>> watchAllEntries() => Stream.value([]);

  @override
  Stream<List<LogEntryModel>> watchEntriesInRange(
    String templateId, {
    required DateTime start,
    required DateTime end,
  }) =>
      Stream.value([]);

  @override
  Stream<List<LogEntryWithContext>> watchPastEntriesWithContext({
    String? templateId,
    DateTime? startDate,
    DateTime? endDate,
    bool sortAscending = false,
  }) =>
      Stream.value([]);

  @override
  Stream<List<LogEntryWithContext>> watchUpcomingEntriesWithContext({
    String? templateId,
    DateTime? startDate,
    DateTime? endDate,
    bool sortAscending = true,
  }) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub TemplateQueryDao — returns empty data for all queries.
class StubTemplateQueryDao implements TemplateQueryDao {
  @override
  Stream<List<TrackerTemplateModel>> watch({bool? isArchived, bool? isHidden}) =>
      Stream.value([]);

  @override
  Future<List<TrackerTemplateModel>> findAll({bool? isArchived, bool? isHidden}) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub TemplateWithAestheticsRepository — returns empty data.
class StubTemplateWithAestheticsRepository implements TemplateWithAestheticsRepository {
  @override
  Stream<List<TemplateWithAesthetics>> watch({bool? isArchived, bool? isHidden}) =>
      Stream.value([]);

  @override
  Future<TemplateWithAesthetics?> findById(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub ScheduleRepository — returns empty data.
class StubScheduleRepository implements ScheduleRepository {
  @override
  Stream<List<ScheduleModel>> watchAllSchedules() => Stream.value([]);

  @override
  Stream<List<ScheduleModel>> watchActiveSchedules() => Stream.value([]);

  @override
  Stream<List<ScheduleModel>> watchSchedulesForTemplate(String templateId) =>
      Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub LogEntryService — no-op on all methods.
class StubLogEntryService implements LogEntryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub ScheduleService — no-op on all methods.
class StubScheduleService implements ScheduleService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

// ─────────────────────────────────────────────────────────────────────────────
// Service stubs (noSuchMethod — never called during screenshot rendering)
// ─────────────────────────────────────────────────────────────────────────────

class StubCryptoKeyRepository extends Mock implements ICryptoKeyRepository {
  StubCryptoKeyRepository() {
    // Register fallback values for all return types
    when(() => getDeviceSigningPublicKeyHex()).thenAnswer((_) async => null);
    when(() => isCrossDeviceStorageAvailable).thenReturn(false);
    when(() => crossDeviceLabel).thenReturn('iCloud');
    when(() => getKeyStatus()).thenAnswer((_) async => CryptoKeyStatus.ready);
  }
}

class StubDeviceInfoService extends Mock implements DeviceInfoService {
  StubDeviceInfoService() {
    when(() => getDeviceName()).thenAnswer((_) async => 'Test Device');
  }
}

class StubAuthRepository extends Mock implements AuthRepository {
  StubAuthRepository() {
    when(() => isRegisteredWithServer).thenAnswer((_) async => false);
  }
}

class StubPermissionService extends Mock implements PermissionService {
  StubPermissionService() {
    when(() => ensureCamera()).thenAnswer((_) async => true);
  }
}

class StubDeleteOrchestrator extends Mock implements DeleteOrchestrator {
  StubDeleteOrchestrator() {
    when(() => deleteAccount()).thenAnswer((_) async {});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell-level cubit stubs (emit default idle state, never touch real deps)
// ─────────────────────────────────────────────────────────────────────────────

class StubAccountInfoCubit extends Cubit<AccountInfoState>
    implements AccountInfoCubit {
  StubAccountInfoCubit() : super(const AccountInfoState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubAppSyncingCubit extends Cubit<AppSyncingState>
    implements AppSyncingCubit {
  StubAppSyncingCubit() : super(const AppSyncingState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubEntitlementCubit extends Cubit<EntitlementState>
    implements EntitlementCubit {
  StubEntitlementCubit() : super(const EntitlementState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubPurchaseCubit extends Cubit<PurchaseState>
    implements PurchaseCubit {
  StubPurchaseCubit() : super(const PurchaseState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubErrorsCubit extends Cubit<ErrorsState>
    implements ErrorsCubit {
  StubErrorsCubit() : super(const ErrorsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubLlmProviderCubit extends Cubit<LlmProviderState>
    implements LlmProviderCubit {
  StubLlmProviderCubit() : super(const LlmProviderState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  StubSyncStatusCubit() : super(const SyncStatusState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubAnalyticsCubit extends Cubit<AnalyticsState>
    implements AnalyticsCubit {
  StubAnalyticsCubit() : super(const AnalyticsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubHealthSyncCubit extends Cubit<HealthSyncState>
    implements HealthSyncCubit {
  StubHealthSyncCubit() : super(const HealthSyncState());

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

// ─────────────────────────────────────────────────────────────────────────────
// Factory cubit stubs (for route-level providers in screenshot tests)
// ─────────────────────────────────────────────────────────────────────────────

class StubDataExportCubit extends Cubit<DataExportState>
    implements DataExportCubit {
  StubDataExportCubit() : super(const DataExportState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubRecoveryKeyCubit extends Cubit<RecoveryKeyState>
    implements RecoveryKeyCubit {
  StubRecoveryKeyCubit() : super(const RecoveryKeyState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubDeviceManagementCubit extends Cubit<DeviceManagementState>
    implements DeviceManagementCubit {
  StubDeviceManagementCubit() : super(const DeviceManagementState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubWebhookCubit extends Cubit<WebhookState>
    implements WebhookCubit {
  StubWebhookCubit() : super(const WebhookState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubFeedbackCubit extends Cubit<FeedbackState>
    implements FeedbackCubit {
  StubFeedbackCubit() : super(const FeedbackState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubResultsListCubit extends Cubit<ResultsListState>
    implements ResultsListCubit {
  StubResultsListCubit() : super(const ResultsListState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

class StubVisualizationCubit extends Cubit<VisualizationState>
    implements VisualizationCubit {
  StubVisualizationCubit() : super(const VisualizationState());
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}

/// Stub NoticesCubit — provides empty notifications state.
class StubNoticesCubit extends Cubit<NoticesState>
    implements NoticesCubit {
  StubNoticesCubit() : super(const NoticesState());

  @override
  void loadNotifications() {} // No-op

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value();
}
