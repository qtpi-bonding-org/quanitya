import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;
import 'package:flutter_adaptable_group/flutter_adaptable_group.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../design_system/primitives/app_sizes.dart';
import '../app_router.dart';
import '../infrastructure/feedback/localization_service.dart';
import '../infrastructure/platform/app_lifecycle_service.dart';
import '../design_system/theme/app_theme.dart';
import '../design_system/theme/theme_service.dart';
import '../design_system/primitives/ui_scaler.dart';
import 'bootstrap.dart';

import '../features/guided_tour/guided_tour_service.dart';
import '../infrastructure/crypto/crypto_key_repository.dart';
import '../infrastructure/device/device_info_service.dart';
import '../infrastructure/auth/auth_repository.dart';
import '../data/repositories/template_with_aesthetics_repository.dart';
import '../data/dao/template_query_dao.dart';
import '../infrastructure/fonts/font_preloader_service.dart';
import '../logic/templates/services/engine/symbolic_combination_generator.dart';
import '../logic/templates/services/sharing/shareable_template_staging.dart';
import '../infrastructure/permissions/permission_service.dart';
import '../infrastructure/platform/platform_capability_service.dart';
import '../infrastructure/auth/delete_orchestrator.dart';

import '../features/analytics/cubits/analytics_message_mapper.dart';
import '../features/app_syncing_mode/cubits/app_syncing_message_mapper.dart';
import '../features/settings/cubits/data_export/data_export_message_mapper.dart';
import '../features/settings/cubits/device_management/device_management_message_mapper.dart';
import '../features/purchase/cubits/entitlement_message_mapper.dart';
import '../features/errors/cubits/errors_message_mapper.dart';
import '../features/user_feedback/mappers/feedback_message_mapper.dart';
import '../features/settings/cubits/llm_provider/llm_provider_message_mapper.dart';
import '../features/notices/mappers/notices_message_mapper.dart';
import '../features/onboarding/services/onboarding_message_mapper.dart';
import '../features/device_pairing/services/pairing_message_mapper.dart';
import '../features/purchase/cubits/purchase_message_mapper.dart';
import '../features/settings/cubits/recovery_key/recovery_key_message_mapper.dart';
import '../features/schedules/cubits/schedule_list_message_mapper.dart';
import '../features/sync_status/cubits/sync_status_message_mapper.dart';
import '../logic/templates/services/shared/template_editor_message_mapper.dart';
import '../features/settings/cubits/webhook/webhook_message_mapper.dart';
import '../logic/analysis/cubits/analysis_builder_message_mapper.dart';
import '../features/account/cubits/account_info_cubit.dart';
import '../features/app_syncing_mode/cubits/app_syncing_cubit.dart';
import '../features/purchase/cubits/entitlement_cubit.dart';
import '../features/purchase/cubits/purchase_cubit.dart';
import '../features/errors/cubits/errors_cubit.dart';
import '../features/settings/cubits/llm_provider/llm_provider_cubit.dart';
import '../features/sync_status/cubits/sync_status_cubit.dart';
import '../features/hidden_visibility/cubits/hidden_visibility_cubit.dart';
import '../features/notices/cubits/notices_cubit.dart';
import '../features/home/cubits/timeline_data_cubit.dart';
import '../features/schedules/cubits/schedule_list_cubit.dart';
import '../features/analytics/cubits/analytics_cubit.dart';
import '../integrations/flutter/health/health_sync_cubit.dart';

class QuanityaApp extends StatefulWidget {
  const QuanityaApp({super.key});

  @override
  State<QuanityaApp> createState() => _QuanityaAppState();
}

class _QuanityaAppState extends State<QuanityaApp> {
  @override
  void initState() {
    super.initState();
    getIt<AppLifecycleService>().init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Singleton cubits (shared state)
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
        // UiFlow internal services
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
        // Page-level message mappers
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
        // Singleton services (batch 3)
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
      child: ListenableBuilder(
        listenable: getIt<ThemeService>(),
        builder: (context, child) {
          final themeService = getIt<ThemeService>();
          return MaterialApp.router(
            routerConfig: AppRouter.router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              UiScaler.instance.init(context);

              final l10n = AppLocalizations.of(context);
              if (l10n != null) {
                final service = getIt<cubit_ui_flow.ILocalizationService>();
                if (service is AppLocalizationService) {
                  service.update(l10n);
                }
              }
              return ResponsiveLayoutConfig(
                baseSpacing: AppSizes.space,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
