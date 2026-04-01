/// Screenshot test bootstrap — registers minimal GetIt services for golden tests.
///
/// Strategy: Register real UI-only services (ThemeService, etc.) and stub/mock
/// data-layer services so the widget tree can render without DB/network/crypto.
library;

import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:quanitya_flutter/app/bootstrap.dart' show getIt;
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart';
import 'package:quanitya_flutter/data/repositories/schedule_repository.dart';
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart';
import 'package:quanitya_flutter/design_system/theme/app_theme.dart';
import 'package:quanitya_flutter/design_system/theme/theme_service.dart';
import 'package:quanitya_flutter/features/account/cubits/account_info_cubit.dart';
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import 'package:quanitya_flutter/features/errors/cubits/errors_cubit.dart';
import 'package:quanitya_flutter/features/guided_tour/guided_tour_service.dart';
import 'package:quanitya_flutter/features/hidden_visibility/cubits/hidden_visibility_cubit.dart';
import 'package:quanitya_flutter/features/home/cubits/temporal_timeline_cubit.dart';
import 'package:quanitya_flutter/features/home/cubits/timeline_data_cubit.dart';
import 'package:quanitya_flutter/features/notices/cubits/notices_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart';
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart';
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_cubit.dart';
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_cubit.dart';
import 'package:quanitya_flutter/features/templates/cubits/list/template_list_cubit.dart';
import 'package:quanitya_flutter/infrastructure/feedback/localization_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/app_lifecycle_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/platform_capability_service.dart';
import 'package:quanitya_flutter/infrastructure/platform/platform_local_auth.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';
import 'package:quanitya_flutter/l10n/app_localizations.dart';
import 'package:quanitya_flutter/logic/log_entries/services/log_entry_service.dart';
import 'package:quanitya_flutter/logic/schedules/services/schedule_service.dart';

import 'stubs/stub_services.dart';

/// Configure GetIt with minimal services needed for screenshot golden tests.
///
/// This avoids PowerSync, network, crypto, and all platform channels.
/// Only UI-rendering services are registered.
Future<void> configureScreenshotDependencies() async {
  // Reset GetIt to clean state
  await getIt.reset();

  // ── Real UI-only services ──────────────────────────────────────────────

  getIt.registerSingleton<ThemeService>(ThemeService());
  getIt.registerLazySingleton<AppLifecycleService>(() => AppLifecycleService());
  getIt.registerLazySingleton<PlatformCapabilityService>(
    () => PlatformCapabilityService(),
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

  // Secure storage + preferences stubs
  final stubStorage = StubSecureStorage();
  final stubPrefs = SecurePreferences(stubStorage);
  getIt.registerLazySingleton<SecurePreferences>(() => stubPrefs);

  // Guided tour — uses stub prefs (always says "tour seen")
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

  // ── Cubits (using stub data) ───────────────────────────────────────────

  getIt.registerFactory<TemporalTimelineCubit>(() => TemporalTimelineCubit());

  getIt.registerFactory<TimelineDataCubit>(
    () => TimelineDataCubit(
      getIt<ILogEntryRepository>(),
      getIt<TemplateQueryDao>(),
    ),
  );

  getIt.registerFactory<ScheduleListCubit>(
    () => ScheduleListCubit(
      getIt<ScheduleRepository>(),
      getIt<TemplateWithAestheticsRepository>(),
      getIt<ScheduleService>(),
    ),
  );

  getIt.registerFactory<TemplateListCubit>(
    () => TemplateListCubit(
      getIt<TemplateWithAestheticsRepository>(),
      getIt<LogEntryService>(),
    ),
  );

  getIt.registerLazySingleton<HiddenVisibilityCubit>(
    () => HiddenVisibilityCubit(
      getIt<PlatformLocalAuth>(),
      getIt<cubit_ui_flow.ILocalizationService>(),
    ),
  );

  // Shell-level cubits (stubs that emit idle/empty state)
  getIt.registerLazySingleton<AccountInfoCubit>(() => StubAccountInfoCubit());
  getIt.registerLazySingleton<AppSyncingCubit>(() => StubAppSyncingCubit());
  getIt.registerLazySingleton<EntitlementCubit>(() => StubEntitlementCubit());
  getIt.registerLazySingleton<PurchaseCubit>(() => StubPurchaseCubit());
  getIt.registerFactory<NoticesCubit>(() => StubNoticesCubit());
  getIt.registerLazySingleton<ErrorsCubit>(() => StubErrorsCubit());
  getIt.registerLazySingleton<LlmProviderCubit>(() => StubLlmProviderCubit());
}

/// Build a minimal MaterialApp that renders the given child with full Quanitya theming.
///
/// This bypasses AppRouter entirely — we render a specific page directly.
Widget buildScreenshotApp({required Widget child}) {
  final themeService = getIt<ThemeService>();

  return MaterialApp(
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
    home: child,
  );
}
