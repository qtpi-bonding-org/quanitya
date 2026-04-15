/// Screenshot test bootstrap — registers minimal GetIt services for golden tests.
///
/// Strategy: Register every type that app.dart's MultiProvider resolves from
/// GetIt, using real no-op services where possible and noSuchMethod stubs for
/// services with platform/network/crypto dependencies.
///
/// This mirrors the full provider tree so ANY page can be screenshot-tested
/// without missing-provider errors.
library;

import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;

// Theme + design system
import 'package:quanitya_flutter/design_system/theme/app_theme.dart';
import 'package:quanitya_flutter/design_system/theme/theme_service.dart';
import 'package:quanitya_flutter/l10n/app_localizations.dart';
import 'package:quanitya_flutter/infrastructure/feedback/localization_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/app_lifecycle_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/haptics.dart';
import 'package:quanitya_flutter/infrastructure/platform/platform_capability_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/platform_local_auth.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';

// Data layer
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart';
import 'package:quanitya_flutter/data/repositories/schedule_repository.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/logic/log_entries/services/log_entry_service.dart';
import 'package:quanitya_flutter/logic/schedules/services/schedule_service.dart';

// Singleton cubits (all 13 from app.dart MultiProvider)
import 'package:quanitya_flutter/features/account/cubits/account_info_cubit.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart';
import 'package:quanitya_flutter/features/errors/cubits/errors_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_cubit.dart';
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_cubit.dart';
import 'package:quanitya_flutter/features/hidden_visibility/cubits/hidden_visibility_cubit.dart';
import 'package:quanitya_flutter/features/notices/cubits/notices_cubit.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_cubit.dart';
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_cubit.dart';
import 'package:quanitya_flutter/features/analytics/cubits/analytics_cubit.dart';
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_cubit.dart';

// Factory cubits used by TemporalHomePage
import 'package:quanitya_flutter/features/home/cubits/temporal_timeline_cubit.dart';
import 'package:quanitya_flutter/features/templates/cubits/list/template_list_cubit.dart';

// Factory cubits for route-level providers (NotebookShell tabs)
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_cubit.dart';
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart';
import 'package:quanitya_flutter/features/results/cubits/results_list_cubit.dart';
import 'package:quanitya_flutter/features/visualization/cubits/visualization_cubit.dart';

// Message mappers (all 19 from app.dart MultiProvider)
import 'package:quanitya_flutter/features/analytics/cubits/analytics_message_mapper.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_message_mapper.dart';
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_message_mapper.dart';
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_message_mapper.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_message_mapper.dart';
import 'package:quanitya_flutter/features/errors/cubits/errors_message_mapper.dart';
import 'package:quanitya_flutter/features/user_feedback/mappers/feedback_message_mapper.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_message_mapper.dart';
import 'package:quanitya_flutter/features/notices/mappers/notices_message_mapper.dart';
import 'package:quanitya_flutter/features/onboarding/services/onboarding_message_mapper.dart';
import 'package:quanitya_flutter/features/device_pairing/services/pairing_message_mapper.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_message_mapper.dart';
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_message_mapper.dart';
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_message_mapper.dart';
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_message_mapper.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/template_editor_message_mapper.dart';
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_message_mapper.dart';
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_message_mapper.dart';

// Singleton services (all 13 from app.dart MultiProvider)
import 'package:quanitya_flutter/features/guided_tour/guided_tour_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/device/device_info_service.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_repository.dart';
import 'package:quanitya_flutter/infrastructure/fonts/font_preloader_service.dart';
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart';
import 'package:quanitya_flutter/logic/templates/services/shared/default_value_handler.dart';
import 'package:quanitya_flutter/logic/templates/services/sharing/shareable_template_staging.dart';
import 'package:quanitya_flutter/infrastructure/permissions/permission_service.dart';
import 'package:quanitya_flutter/infrastructure/auth/delete_orchestrator.dart';

// Exception mapper
import 'package:quanitya_flutter/infrastructure/feedback/exception_mapper.dart';

import 'stubs/stub_services.dart';

/// Configure GetIt with all services needed for screenshot golden tests.
///
/// Registers everything that app.dart's MultiProvider resolves from GetIt,
/// so the full provider tree can be constructed for any page.
Future<void> configureScreenshotDependencies() async {
  // Reset GetIt to clean state
  await getIt.reset();

  // ── Real UI-only services ──────────────────────────────────────────────

  getIt.registerSingleton<ThemeService>(ThemeService());
  getIt.registerLazySingleton<AppLifecycleService>(() => AppLifecycleService());
  getIt.registerLazySingleton<PlatformCapabilityService>(
    () => PlatformCapabilityService(),
  );
  getIt.registerLazySingleton<Haptics>(
    () => Haptics(getIt<PlatformCapabilityService>()),
  );

  // Localization service (real — gets updated when MaterialApp builds)
  final locService = AppLocalizationService();
  getIt.registerLazySingleton<cubit_ui_flow.ILocalizationService>(
    () => locService,
  );

  // Feedback/loading stubs (no-op — we don't show toasts in screenshots)
  getIt.registerLazySingleton<cubit_ui_flow.IFeedbackService>(
    () => StubFeedbackService(),
  );
  getIt.registerLazySingleton<cubit_ui_flow.ILoadingService>(
    () => StubLoadingService(),
  );

  // Exception key mapper (real — no deps, pure mapping logic)
  getIt.registerLazySingleton<cubit_ui_flow.IExceptionKeyMapper>(
    () => QuanityaExceptionKeyMapper(),
  );

  // UiFlow service (real — wires localization + feedback + loading)
  getIt.registerLazySingleton<cubit_ui_flow.IUiFlowService>(
    () => cubit_ui_flow.UiFlowService(
      localization: getIt<cubit_ui_flow.ILocalizationService>(),
      feedback: getIt<cubit_ui_flow.IFeedbackService>(),
      loading: getIt<cubit_ui_flow.ILoadingService>(),
    ),
  );

  // Secure storage + preferences stubs
  final stubStorage = StubSecureStorage();
  // Pre-seed tour flags so guided tours don't try to show
  await stubStorage.storeSecureData('tour_home_seen', 'true');
  await stubStorage.storeSecureData('tour_designer_seen', 'true');
  final stubPrefs = SecurePreferences(stubStorage);
  getIt.registerLazySingleton<SecurePreferences>(() => stubPrefs);

  // Guided tour — uses stub prefs (tours marked as seen)
  getIt.registerLazySingleton<GuidedTourService>(
    () => GuidedTourService(stubPrefs),
  );

  // PlatformLocalAuth — used by HiddenVisibilityCubit
  getIt.registerFactory<PlatformLocalAuth>(
    () => PlatformLocalAuth(getIt<PlatformCapabilityService>()),
  );

  // ── Stub data layer ────────────────────────────────────────────────────

  final stubLogEntryRepo = StubLogEntryRepository();
  getIt.registerLazySingleton<ILogEntryRepository>(() => stubLogEntryRepo);

  final stubTemplateQueryDao = StubTemplateQueryDao();
  getIt.registerLazySingleton<TemplateQueryDao>(() => stubTemplateQueryDao);

  final stubTemplateWithAestheticsRepo = StubTemplateWithAestheticsRepository();
  getIt.registerLazySingleton<TemplateWithAestheticsRepository>(
    () => stubTemplateWithAestheticsRepo,
  );

  final stubScheduleRepo = StubScheduleRepository();
  getIt.registerLazySingleton<ScheduleRepository>(() => stubScheduleRepo);

  final stubLogEntryService = StubLogEntryService();
  getIt.registerLazySingleton<LogEntryService>(() => stubLogEntryService);

  final stubScheduleService = StubScheduleService();
  getIt.registerLazySingleton<ScheduleService>(() => stubScheduleService);

  // ── Singleton services (for app.dart MultiProvider) ────────────────────

  // Services with no deps or simple deps
  getIt.registerLazySingleton<FontPreloaderService>(
    () => StubFontPreloaderService(),
  );
  getIt.registerLazySingleton<SymbolicCombinationGenerator>(
    () => SymbolicCombinationGenerator(),
  );
  getIt.registerFactory<DefaultValueHandler>(() => DefaultValueHandler());
  getIt.registerLazySingleton<ShareableTemplateStaging>(
    () => ShareableTemplateStaging(),
  );

  // Services with complex deps — use noSuchMethod stubs
  getIt.registerLazySingleton<ICryptoKeyRepository>(
    () => StubCryptoKeyRepository(),
  );
  getIt.registerLazySingleton<DeviceInfoService>(
    () => StubDeviceInfoService(),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => StubAuthRepository(),
  );
  getIt.registerLazySingleton<PermissionService>(
    () => StubPermissionService(),
  );
  getIt.registerLazySingleton<DeleteOrchestrator>(
    () => StubDeleteOrchestrator(),
  );

  // ── Message mappers (all 19 from app.dart) ─────────────────────────────

  getIt.registerLazySingleton<AnalyticsMessageMapper>(
    () => AnalyticsMessageMapper(),
  );
  getIt.registerLazySingleton<AppSyncingMessageMapper>(
    () => AppSyncingMessageMapper(),
  );
  getIt.registerLazySingleton<DataExportMessageMapper>(
    () => DataExportMessageMapper(),
  );
  getIt.registerLazySingleton<DeviceManagementMessageMapper>(
    () => DeviceManagementMessageMapper(),
  );
  getIt.registerLazySingleton<EntitlementMessageMapper>(
    () => EntitlementMessageMapper(),
  );
  getIt.registerLazySingleton<ErrorsMessageMapper>(
    () => ErrorsMessageMapper(),
  );
  getIt.registerLazySingleton<FeedbackMessageMapper>(
    () => FeedbackMessageMapper(),
  );
  getIt.registerLazySingleton<LlmProviderMessageMapper>(
    () => LlmProviderMessageMapper(),
  );
  getIt.registerLazySingleton<NoticesMessageMapper>(
    () => NoticesMessageMapper(),
  );
  getIt.registerLazySingleton<OnboardingMessageMapper>(
    () => OnboardingMessageMapper(),
  );
  getIt.registerLazySingleton<PairingQrMessageMapper>(
    () => PairingQrMessageMapper(getIt<cubit_ui_flow.IExceptionKeyMapper>()),
  );
  getIt.registerLazySingleton<PairingScanMessageMapper>(
    () => PairingScanMessageMapper(getIt<cubit_ui_flow.IExceptionKeyMapper>()),
  );
  getIt.registerLazySingleton<PurchaseMessageMapper>(
    () => PurchaseMessageMapper(),
  );
  getIt.registerLazySingleton<RecoveryKeyMessageMapper>(
    () => RecoveryKeyMessageMapper(),
  );
  getIt.registerLazySingleton<ScheduleListMessageMapper>(
    () => ScheduleListMessageMapper(),
  );
  getIt.registerLazySingleton<SyncStatusMessageMapper>(
    () => SyncStatusMessageMapper(),
  );
  getIt.registerLazySingleton<TemplateEditorMessageMapper>(
    () => TemplateEditorMessageMapper(),
  );
  getIt.registerLazySingleton<WebhookMessageMapper>(
    () => WebhookMessageMapper(),
  );
  getIt.registerLazySingleton<AnalysisBuilderMessageMapper>(
    () => AnalysisBuilderMessageMapper(),
  );

  // ── Factory cubits (created per-page) ──────────────────────────────────

  getIt.registerFactory<TemporalTimelineCubit>(() => TemporalTimelineCubit());

  getIt.registerFactory<TemplateListCubit>(
    () => TemplateListCubit(
      getIt<TemplateWithAestheticsRepository>(),
      getIt<LogEntryService>(),
    ),
  );

  // ── Singleton cubits (all 13 from app.dart MultiProvider) ──────────────

  // TimelineData and ScheduleList use stub cubits (not real ones with repos)
  // so we can emit pre-built state for different screenshots.
  getIt.registerLazySingleton<TimelineDataCubit>(
    () => StubTimelineDataCubit(),
  );
  getIt.registerLazySingleton<ScheduleListCubit>(
    () => StubScheduleListCubit(),
  );

  getIt.registerLazySingleton<HiddenVisibilityCubit>(
    () => StubHiddenVisibilityCubit(),
  );

  // Shell-level cubits (stubs that emit idle/empty state)
  getIt.registerLazySingleton<AccountInfoCubit>(() => StubAccountInfoCubit());
  getIt.registerLazySingleton<AppSyncingCubit>(() => StubAppSyncingCubit());
  getIt.registerLazySingleton<EntitlementCubit>(() => StubEntitlementCubit());
  getIt.registerLazySingleton<PurchaseCubit>(() => StubPurchaseCubit());
  getIt.registerLazySingleton<NoticesCubit>(() => StubNoticesCubit());
  getIt.registerLazySingleton<ErrorsCubit>(() => StubErrorsCubit());
  getIt.registerLazySingleton<LlmProviderCubit>(() => StubLlmProviderCubit());
  getIt.registerLazySingleton<SyncStatusCubit>(() => StubSyncStatusCubit());
  getIt.registerLazySingleton<AnalyticsCubit>(() => StubAnalyticsCubit());
  getIt.registerLazySingleton<HealthSyncCubit>(() => StubHealthSyncCubit());

  // Factory cubits for route-level providers (NotebookShell tabs)
  getIt.registerFactory<DataExportCubit>(() => StubDataExportCubit());
  getIt.registerFactory<RecoveryKeyCubit>(() => StubRecoveryKeyCubit());
  getIt.registerFactory<DeviceManagementCubit>(() => StubDeviceManagementCubit());
  getIt.registerFactory<WebhookCubit>(() => StubWebhookCubit());
  getIt.registerFactory<FeedbackCubit>(() => StubFeedbackCubit());

  // Sub-widget cubits (created inside IndexedStack pages)
  getIt.registerFactory<ResultsListCubit>(() => StubResultsListCubit());
  getIt.registerFactory<VisualizationCubit>(() => StubVisualizationCubit());
}

/// Build a MaterialApp wrapped in the same MultiProvider as app.dart.
///
/// This replicates the exact provider tree from QuanityaApp so any page
/// can access all cubits, services, and mappers via context.read/watch.
Widget buildScreenshotApp({required Widget child, Locale? locale}) {
  final themeService = getIt<ThemeService>();

  return MultiProvider(
    providers: [
      // Singleton cubits (13 — same order as app.dart)
      BlocProvider<AccountInfoCubit>.value(value: getIt<AccountInfoCubit>()),
      BlocProvider<AppSyncingCubit>.value(value: getIt<AppSyncingCubit>()),
      BlocProvider<EntitlementCubit>.value(value: getIt<EntitlementCubit>()),
      BlocProvider<PurchaseCubit>.value(value: getIt<PurchaseCubit>()),
      BlocProvider<ErrorsCubit>.value(value: getIt<ErrorsCubit>()),
      BlocProvider<LlmProviderCubit>.value(value: getIt<LlmProviderCubit>()),
      BlocProvider<SyncStatusCubit>.value(value: getIt<SyncStatusCubit>()),
      BlocProvider<HiddenVisibilityCubit>.value(
          value: getIt<HiddenVisibilityCubit>()),
      BlocProvider<NoticesCubit>.value(value: getIt<NoticesCubit>()),
      BlocProvider<TimelineDataCubit>.value(value: getIt<TimelineDataCubit>()),
      BlocProvider<ScheduleListCubit>.value(value: getIt<ScheduleListCubit>()),
      BlocProvider<AnalyticsCubit>.value(value: getIt<AnalyticsCubit>()),
      BlocProvider<HealthSyncCubit>.value(value: getIt<HealthSyncCubit>()),
      // UiFlow internal services (4)
      Provider<cubit_ui_flow.IExceptionKeyMapper>.value(
        value: getIt<cubit_ui_flow.IExceptionKeyMapper>(),
      ),
      Provider<cubit_ui_flow.ILocalizationService>.value(
        value: getIt<cubit_ui_flow.ILocalizationService>(),
      ),
      Provider<cubit_ui_flow.IFeedbackService>.value(
        value: getIt<cubit_ui_flow.IFeedbackService>(),
      ),
      Provider<cubit_ui_flow.ILoadingService>.value(
        value: getIt<cubit_ui_flow.ILoadingService>(),
      ),
      // Message mappers (19)
      Provider<AnalyticsMessageMapper>.value(
        value: getIt<AnalyticsMessageMapper>(),
      ),
      Provider<AppSyncingMessageMapper>.value(
        value: getIt<AppSyncingMessageMapper>(),
      ),
      Provider<DataExportMessageMapper>.value(
        value: getIt<DataExportMessageMapper>(),
      ),
      Provider<DeviceManagementMessageMapper>.value(
        value: getIt<DeviceManagementMessageMapper>(),
      ),
      Provider<EntitlementMessageMapper>.value(
        value: getIt<EntitlementMessageMapper>(),
      ),
      Provider<ErrorsMessageMapper>.value(
        value: getIt<ErrorsMessageMapper>(),
      ),
      Provider<FeedbackMessageMapper>.value(
        value: getIt<FeedbackMessageMapper>(),
      ),
      Provider<LlmProviderMessageMapper>.value(
        value: getIt<LlmProviderMessageMapper>(),
      ),
      Provider<NoticesMessageMapper>.value(
        value: getIt<NoticesMessageMapper>(),
      ),
      Provider<OnboardingMessageMapper>.value(
        value: getIt<OnboardingMessageMapper>(),
      ),
      Provider<PairingQrMessageMapper>.value(
        value: getIt<PairingQrMessageMapper>(),
      ),
      Provider<PairingScanMessageMapper>.value(
        value: getIt<PairingScanMessageMapper>(),
      ),
      Provider<PurchaseMessageMapper>.value(
        value: getIt<PurchaseMessageMapper>(),
      ),
      Provider<RecoveryKeyMessageMapper>.value(
        value: getIt<RecoveryKeyMessageMapper>(),
      ),
      Provider<ScheduleListMessageMapper>.value(
        value: getIt<ScheduleListMessageMapper>(),
      ),
      Provider<SyncStatusMessageMapper>.value(
        value: getIt<SyncStatusMessageMapper>(),
      ),
      Provider<TemplateEditorMessageMapper>.value(
        value: getIt<TemplateEditorMessageMapper>(),
      ),
      Provider<WebhookMessageMapper>.value(
        value: getIt<WebhookMessageMapper>(),
      ),
      Provider<AnalysisBuilderMessageMapper>.value(
        value: getIt<AnalysisBuilderMessageMapper>(),
      ),
      // Singleton services (13)
      Provider<GuidedTourService>.value(value: getIt<GuidedTourService>()),
      Provider<ICryptoKeyRepository>.value(
        value: getIt<ICryptoKeyRepository>(),
      ),
      Provider<DeviceInfoService>.value(value: getIt<DeviceInfoService>()),
      Provider<AuthRepository>.value(value: getIt<AuthRepository>()),
      Provider<TemplateWithAestheticsRepository>.value(
        value: getIt<TemplateWithAestheticsRepository>(),
      ),
      Provider<TemplateQueryDao>.value(value: getIt<TemplateQueryDao>()),
      Provider<FontPreloaderService>.value(
        value: getIt<FontPreloaderService>(),
      ),
      Provider<SymbolicCombinationGenerator>.value(
        value: getIt<SymbolicCombinationGenerator>(),
      ),
      Provider<ShareableTemplateStaging>.value(
        value: getIt<ShareableTemplateStaging>(),
      ),
      Provider<PermissionService>.value(value: getIt<PermissionService>()),
      Provider<PlatformCapabilityService>.value(
        value: getIt<PlatformCapabilityService>(),
      ),
      Provider<DeleteOrchestrator>.value(value: getIt<DeleteOrchestrator>()),
      Provider<cubit_ui_flow.IUiFlowService>.value(
        value: getIt<cubit_ui_flow.IUiFlowService>(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    ),
  );
}
