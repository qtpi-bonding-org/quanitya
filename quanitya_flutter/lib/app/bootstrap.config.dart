// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as _i653;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart' as _i711;
import 'package:quanitya_flutter/app/app_module.dart' as _i1028;
import 'package:quanitya_flutter/data/dao/analysis_script_dual_dao.dart'
    as _i886;
import 'package:quanitya_flutter/data/dao/analysis_script_query_dao.dart'
    as _i145;
import 'package:quanitya_flutter/data/dao/analytics_inbox_dao.dart' as _i302;
import 'package:quanitya_flutter/data/dao/dual_dao.dart' as _i670;
import 'package:quanitya_flutter/data/dao/error_box_dao.dart' as _i292;
import 'package:quanitya_flutter/data/dao/fts_search_dao.dart' as _i523;
import 'package:quanitya_flutter/data/dao/log_entry_dual_dao.dart' as _i896;
import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart' as _i95;
import 'package:quanitya_flutter/data/dao/notification_dao.dart' as _i702;
import 'package:quanitya_flutter/data/dao/schedule_dual_dao.dart' as _i233;
import 'package:quanitya_flutter/data/dao/schedule_query_dao.dart' as _i318;
import 'package:quanitya_flutter/data/dao/template_aesthetics_dual_dao.dart'
    as _i14;
import 'package:quanitya_flutter/data/dao/template_query_dao.dart' as _i870;
import 'package:quanitya_flutter/data/dao/tracker_template_dual_dao.dart'
    as _i285;
import 'package:quanitya_flutter/data/db/app_database.dart' as _i147;
import 'package:quanitya_flutter/data/interfaces/analysis_script_interface.dart'
    as _i810;
import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart'
    as _i34;
import 'package:quanitya_flutter/data/repositories/analysis_script_repository.dart'
    as _i141;
import 'package:quanitya_flutter/data/repositories/analytics_inbox_repository.dart'
    as _i743;
import 'package:quanitya_flutter/data/repositories/calculation_repository.dart'
    as _i679;
import 'package:quanitya_flutter/data/repositories/data_export_repository.dart'
    as _i198;
import 'package:quanitya_flutter/data/repositories/data_retrieval_service.dart'
    as _i825;
import 'package:quanitya_flutter/data/repositories/e2ee_puller.dart' as _i156;
import 'package:quanitya_flutter/data/repositories/error_box_repository.dart'
    as _i867;
import 'package:quanitya_flutter/data/repositories/fts_search_repository.dart'
    as _i558;
import 'package:quanitya_flutter/data/repositories/log_entry_repository.dart'
    as _i328;
import 'package:quanitya_flutter/data/repositories/notification_repository.dart'
    as _i41;
import 'package:quanitya_flutter/data/repositories/schedule_repository.dart'
    as _i723;
import 'package:quanitya_flutter/data/repositories/template_with_aesthetics_repository.dart'
    as _i554;
import 'package:quanitya_flutter/data/sync/powersync_service.dart' as _i475;
import 'package:quanitya_flutter/design_system/theme/theme_service.dart'
    as _i75;
import 'package:quanitya_flutter/dev/services/dev_seeder_service.dart' as _i330;
import 'package:quanitya_flutter/features/account/cubits/account_info_cubit.dart'
    as _i404;
import 'package:quanitya_flutter/features/analytics/cubits/analytics_cubit.dart'
    as _i341;
import 'package:quanitya_flutter/features/analytics/cubits/analytics_message_mapper.dart'
    as _i175;
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_cubit.dart'
    as _i407;
import 'package:quanitya_flutter/features/app_syncing_mode/cubits/app_syncing_message_mapper.dart'
    as _i412;
import 'package:quanitya_flutter/features/app_syncing_mode/repositories/app_syncing_repository.dart'
    as _i62;
import 'package:quanitya_flutter/features/catalog/cubits/template_gallery_cubit.dart'
    as _i824;
import 'package:quanitya_flutter/features/catalog/cubits/template_gallery_message_mapper.dart'
    as _i274;
import 'package:quanitya_flutter/features/catalog/services/template_catalog_service.dart'
    as _i726;
import 'package:quanitya_flutter/features/device_pairing/cubits/pairing_qr_cubit.dart'
    as _i1000;
import 'package:quanitya_flutter/features/device_pairing/cubits/pairing_scan_cubit.dart'
    as _i813;
import 'package:quanitya_flutter/features/device_pairing/services/pairing_message_mapper.dart'
    as _i1027;
import 'package:quanitya_flutter/features/device_pairing/services/pairing_service.dart'
    as _i258;
import 'package:quanitya_flutter/features/errors/cubits/errors_cubit.dart'
    as _i562;
import 'package:quanitya_flutter/features/errors/cubits/errors_message_mapper.dart'
    as _i792;
import 'package:quanitya_flutter/features/guided_tour/guided_tour_service.dart'
    as _i922;
import 'package:quanitya_flutter/features/hidden_visibility/cubits/hidden_visibility_cubit.dart'
    as _i932;
import 'package:quanitya_flutter/features/hidden_visibility/cubits/hidden_visibility_message_mapper.dart'
    as _i399;
import 'package:quanitya_flutter/features/home/cubits/temporal_timeline_cubit.dart'
    as _i545;
import 'package:quanitya_flutter/features/home/cubits/temporal_timeline_message_mapper.dart'
    as _i1067;
import 'package:quanitya_flutter/features/home/cubits/timeline_data_cubit.dart'
    as _i386;
import 'package:quanitya_flutter/features/home/cubits/timeline_data_message_mapper.dart'
    as _i62;
import 'package:quanitya_flutter/features/log_entry/cubits/detail/entry_detail_cubit.dart'
    as _i39;
import 'package:quanitya_flutter/features/log_entry/cubits/detail/entry_detail_message_mapper.dart'
    as _i570;
import 'package:quanitya_flutter/features/log_entry/cubits/import/import_cubit.dart'
    as _i143;
import 'package:quanitya_flutter/features/notices/cubits/notices_cubit.dart'
    as _i831;
import 'package:quanitya_flutter/features/notices/mappers/notices_message_mapper.dart'
    as _i206;
import 'package:quanitya_flutter/features/onboarding/cubits/onboarding_cubit.dart'
    as _i177;
import 'package:quanitya_flutter/features/onboarding/services/onboarding_message_mapper.dart'
    as _i194;
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_cubit.dart'
    as _i50;
import 'package:quanitya_flutter/features/purchase/cubits/entitlement_message_mapper.dart'
    as _i385;
import 'package:quanitya_flutter/features/purchase/cubits/purchase_cubit.dart'
    as _i160;
import 'package:quanitya_flutter/features/purchase/cubits/purchase_message_mapper.dart'
    as _i753;
import 'package:quanitya_flutter/features/results/cubits/results_list_cubit.dart'
    as _i676;
import 'package:quanitya_flutter/features/results/cubits/results_list_message_mapper.dart'
    as _i516;
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_cubit.dart'
    as _i436;
import 'package:quanitya_flutter/features/schedules/cubits/schedule_list_message_mapper.dart'
    as _i715;
import 'package:quanitya_flutter/features/search/cubits/search_cubit.dart'
    as _i404;
import 'package:quanitya_flutter/features/search/cubits/search_message_mapper.dart'
    as _i533;
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_cubit.dart'
    as _i632;
import 'package:quanitya_flutter/features/settings/cubits/data_export/data_export_message_mapper.dart'
    as _i46;
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_cubit.dart'
    as _i576;
import 'package:quanitya_flutter/features/settings/cubits/device_management/device_management_message_mapper.dart'
    as _i32;
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_cubit.dart'
    as _i155;
import 'package:quanitya_flutter/features/settings/cubits/llm_provider/llm_provider_message_mapper.dart'
    as _i468;
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_cubit.dart'
    as _i65;
import 'package:quanitya_flutter/features/settings/cubits/recovery_key/recovery_key_message_mapper.dart'
    as _i614;
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_cubit.dart'
    as _i431;
import 'package:quanitya_flutter/features/settings/cubits/webhook/webhook_message_mapper.dart'
    as _i935;
import 'package:quanitya_flutter/features/settings/repositories/llm_provider_config_repository.dart'
    as _i872;
import 'package:quanitya_flutter/features/settings/repositories/open_router_model_repository.dart'
    as _i504;
import 'package:quanitya_flutter/features/settings/services/tested_models_service.dart'
    as _i709;
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_cubit.dart'
    as _i25;
import 'package:quanitya_flutter/features/sync_status/cubits/sync_status_message_mapper.dart'
    as _i862;
import 'package:quanitya_flutter/features/templates/cubits/editor/template_editor_cubit.dart'
    as _i291;
import 'package:quanitya_flutter/features/templates/cubits/editor/template_editor_message_mapper.dart'
    as _i1070;
import 'package:quanitya_flutter/features/templates/cubits/form/dynamic_template_cubit.dart'
    as _i839;
import 'package:quanitya_flutter/features/templates/cubits/form/dynamic_template_message_mapper.dart'
    as _i977;
import 'package:quanitya_flutter/features/templates/cubits/generator/template_generator_cubit.dart'
    as _i135;
import 'package:quanitya_flutter/features/templates/cubits/generator/template_generator_message_mapper.dart'
    as _i963;
import 'package:quanitya_flutter/features/templates/cubits/list/template_list_cubit.dart'
    as _i966;
import 'package:quanitya_flutter/features/templates/cubits/list/template_list_message_mapper.dart'
    as _i776;
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_export_cubit.dart'
    as _i195;
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_export_message_mapper.dart'
    as _i467;
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_import_cubit.dart'
    as _i77;
import 'package:quanitya_flutter/features/templates/cubits/sharing/template_sharing_import_message_mapper.dart'
    as _i166;
import 'package:quanitya_flutter/features/user_feedback/cubits/feedback_cubit.dart'
    as _i714;
import 'package:quanitya_flutter/features/user_feedback/mappers/feedback_message_mapper.dart'
    as _i804;
import 'package:quanitya_flutter/features/visualization/cubits/visualization_cubit.dart'
    as _i831;
import 'package:quanitya_flutter/features/visualization/cubits/visualization_message_mapper.dart'
    as _i1069;
import 'package:quanitya_flutter/infrastructure/auth/account_service.dart'
    as _i401;
import 'package:quanitya_flutter/infrastructure/auth/auth_account_orchestrator.dart'
    as _i7;
import 'package:quanitya_flutter/infrastructure/auth/auth_repository.dart'
    as _i515;
import 'package:quanitya_flutter/infrastructure/auth/auth_service.dart' as _i71;
import 'package:quanitya_flutter/infrastructure/auth/delete_orchestrator.dart'
    as _i984;
import 'package:quanitya_flutter/infrastructure/auth/local_auth_service.dart'
    as _i174;
import 'package:quanitya_flutter/infrastructure/config/app_config.dart'
    as _i557;
import 'package:quanitya_flutter/infrastructure/crypto/cross_device_key_storage.dart'
    as _i29;
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart'
    as _i367;
import 'package:quanitya_flutter/infrastructure/crypto/data_encryption_service.dart'
    as _i549;
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_cross_device_key_storage.dart'
    as _i453;
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_secure_storage.dart'
    as _i83;
import 'package:quanitya_flutter/infrastructure/crypto/key_export_service.dart'
    as _i246;
import 'package:quanitya_flutter/infrastructure/device/device_info_service.dart'
    as _i201;
import 'package:quanitya_flutter/infrastructure/error_reporting/error_reporter_service.dart'
    as _i106;
import 'package:quanitya_flutter/infrastructure/feedback/exception_mapper.dart'
    as _i620;
import 'package:quanitya_flutter/infrastructure/feedback/feedback_service.dart'
    as _i743;
import 'package:quanitya_flutter/infrastructure/feedback/haptic_service.dart'
    as _i880;
import 'package:quanitya_flutter/infrastructure/feedback/loading_service.dart'
    as _i1002;
import 'package:quanitya_flutter/infrastructure/feedback/localization_service.dart'
    as _i946;
import 'package:quanitya_flutter/infrastructure/fonts/font_preloader_service.dart'
    as _i1024;
import 'package:quanitya_flutter/infrastructure/js_executor/i_js_executor.dart'
    as _i737;
import 'package:quanitya_flutter/infrastructure/js_executor/js_executor_module.dart'
    as _i777;
import 'package:quanitya_flutter/infrastructure/llm/services/llm_chat_service.dart'
    as _i294;
import 'package:quanitya_flutter/infrastructure/llm/services/llm_service.dart'
    as _i637;
import 'package:quanitya_flutter/infrastructure/network/network_repository.dart'
    as _i499;
import 'package:quanitya_flutter/infrastructure/notifications/notification_action_handler.dart'
    as _i886;
import 'package:quanitya_flutter/infrastructure/notifications/notification_service.dart'
    as _i42;
import 'package:quanitya_flutter/infrastructure/permissions/permission_service.dart'
    as _i946;
import 'package:quanitya_flutter/infrastructure/platform/app_lifecycle_service.dart'
    as _i171;
import 'package:quanitya_flutter/infrastructure/platform/platform_capability_service.dart'
    as _i548;
import 'package:quanitya_flutter/infrastructure/platform/platform_local_auth.dart'
    as _i560;
import 'package:quanitya_flutter/infrastructure/platform/platform_notification_service.dart'
    as _i753;
import 'package:quanitya_flutter/infrastructure/platform/platform_secure_storage.dart'
    as _i1035;
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart'
    as _i788;
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart'
    as _i494;
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_repository.dart'
    as _i884;
import 'package:quanitya_flutter/infrastructure/purchase/entitlement_service.dart'
    as _i695;
import 'package:quanitya_flutter/infrastructure/purchase/i_digital_purchase_repository.dart'
    as _i190;
import 'package:quanitya_flutter/infrastructure/purchase/i_entitlement_service.dart'
    as _i636;
import 'package:quanitya_flutter/infrastructure/purchase/i_purchase_service.dart'
    as _i426;
import 'package:quanitya_flutter/infrastructure/purchase/providers/in_app_purchase_repository.dart'
    as _i59;
import 'package:quanitya_flutter/infrastructure/purchase/purchase_service.dart'
    as _i163;
import 'package:quanitya_flutter/infrastructure/security/database_key_service.dart'
    as _i189;
import 'package:quanitya_flutter/infrastructure/sync/sync_service.dart'
    as _i851;
import 'package:quanitya_flutter/infrastructure/units/unit_service.dart'
    as _i866;
import 'package:quanitya_flutter/infrastructure/user_feedback/feedback_submission_service.dart'
    as _i277;
import 'package:quanitya_flutter/infrastructure/webhooks/api_key_repository.dart'
    as _i132;
import 'package:quanitya_flutter/infrastructure/webhooks/webhook_repository.dart'
    as _i305;
import 'package:quanitya_flutter/infrastructure/webhooks/webhook_service.dart'
    as _i581;
import 'package:quanitya_flutter/integrations/external/integration_registry.dart'
    as _i1062;
import 'package:quanitya_flutter/integrations/flutter/health/health_adapter_factory.dart'
    as _i419;
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_cubit.dart'
    as _i611;
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_message_mapper.dart'
    as _i94;
import 'package:quanitya_flutter/integrations/flutter/health/health_sync_service.dart'
    as _i746;
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_cubit.dart'
    as _i873;
import 'package:quanitya_flutter/logic/analysis/cubits/analysis_builder_message_mapper.dart'
    as _i894;
import 'package:quanitya_flutter/logic/analysis/services/ai/ai_analysis_orchestrator.dart'
    as _i790;
import 'package:quanitya_flutter/logic/analysis/services/analysis_engine.dart'
    as _i820;
import 'package:quanitya_flutter/logic/analysis/services/field_shape_resolver.dart'
    as _i939;
import 'package:quanitya_flutter/logic/analysis/services/streaming_analytics_service.dart'
    as _i60;
import 'package:quanitya_flutter/logic/analysis/services/wasm_analysis_service.dart'
    as _i193;
import 'package:quanitya_flutter/logic/analytics/analytics_service.dart'
    as _i985;
import 'package:quanitya_flutter/logic/calculations/services/calculation_service.dart'
    as _i618;
import 'package:quanitya_flutter/logic/import/services/import_executor.dart'
    as _i874;
import 'package:quanitya_flutter/logic/ingestion/adapters/adapter_registry.dart'
    as _i763;
import 'package:quanitya_flutter/logic/ingestion/services/data_ingestion_service.dart'
    as _i75;
import 'package:quanitya_flutter/logic/llm/services/local_llm_service.dart'
    as _i703;
import 'package:quanitya_flutter/logic/log_entries/services/log_entry_service.dart'
    as _i306;
import 'package:quanitya_flutter/logic/ocr/services/ocr_service.dart' as _i531;
import 'package:quanitya_flutter/logic/schedules/services/recurrence_service.dart'
    as _i37;
import 'package:quanitya_flutter/logic/schedules/services/schedule_generator_service.dart'
    as _i840;
import 'package:quanitya_flutter/logic/schedules/services/schedule_service.dart'
    as _i909;
import 'package:quanitya_flutter/logic/templates/models/shared/model_runtime_converter.dart'
    as _i205;
import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_generator.dart'
    as _i808;
import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_orchestrator.dart'
    as _i670;
import 'package:quanitya_flutter/logic/templates/services/ai/ai_template_service.dart'
    as _i867;
import 'package:quanitya_flutter/logic/templates/services/engine/json_to_model_parser.dart'
    as _i953;
import 'package:quanitya_flutter/logic/templates/services/engine/symbolic_combination_generator.dart'
    as _i259;
import 'package:quanitya_flutter/logic/templates/services/engine/template_exception_mapper.dart'
    as _i264;
import 'package:quanitya_flutter/logic/templates/services/engine/unified_schema_generator.dart'
    as _i303;
import 'package:quanitya_flutter/logic/templates/services/shared/default_value_handler.dart'
    as _i962;
import 'package:quanitya_flutter/logic/templates/services/shared/template_editor_message_mapper.dart'
    as _i726;
import 'package:quanitya_flutter/logic/templates/services/shared/wcag_compliance_validator.dart'
    as _i540;
import 'package:quanitya_flutter/logic/templates/services/sharing/shareable_template_staging.dart'
    as _i496;
import 'package:quanitya_flutter/logic/templates/services/sharing/shareable_template_validator.dart'
    as _i943;
import 'package:quanitya_flutter/logic/templates/services/sharing/template_export_service.dart'
    as _i399;
import 'package:quanitya_flutter/logic/templates/services/sharing/template_import_service.dart'
    as _i648;
import 'package:quanitya_flutter/support/utils/uuid_generator.dart' as _i948;

const String _dev = 'dev';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    final jsExecutorModule = _$JsExecutorModule();
    final crossDeviceKeyModule = _$CrossDeviceKeyModule();
    final repositoryModule = _$RepositoryModule();
    gh.factory<String>(() => appModule.localhost);
    gh.factory<_i679.CalculationRepository>(
      () => const _i679.CalculationRepository(),
    );
    gh.factory<_i175.AnalyticsMessageMapper>(
      () => _i175.AnalyticsMessageMapper(),
    );
    gh.factory<_i412.AppSyncingMessageMapper>(
      () => _i412.AppSyncingMessageMapper(),
    );
    gh.factory<_i274.TemplateGalleryMessageMapper>(
      () => _i274.TemplateGalleryMessageMapper(),
    );
    gh.factory<_i792.ErrorsMessageMapper>(() => _i792.ErrorsMessageMapper());
    gh.factory<_i399.HiddenVisibilityMessageMapper>(
      () => _i399.HiddenVisibilityMessageMapper(),
    );
    gh.factory<_i545.TemporalTimelineCubit>(
      () => _i545.TemporalTimelineCubit(),
    );
    gh.factory<_i1067.TemporalTimelineMessageMapper>(
      () => _i1067.TemporalTimelineMessageMapper(),
    );
    gh.factory<_i62.TimelineDataMessageMapper>(
      () => _i62.TimelineDataMessageMapper(),
    );
    gh.factory<_i570.EntryDetailMessageMapper>(
      () => _i570.EntryDetailMessageMapper(),
    );
    gh.factory<_i206.NoticesMessageMapper>(() => _i206.NoticesMessageMapper());
    gh.factory<_i194.OnboardingMessageMapper>(
      () => _i194.OnboardingMessageMapper(),
    );
    gh.factory<_i385.EntitlementMessageMapper>(
      () => _i385.EntitlementMessageMapper(),
    );
    gh.factory<_i753.PurchaseMessageMapper>(
      () => _i753.PurchaseMessageMapper(),
    );
    gh.factory<_i516.ResultsListMessageMapper>(
      () => _i516.ResultsListMessageMapper(),
    );
    gh.factory<_i715.ScheduleListMessageMapper>(
      () => _i715.ScheduleListMessageMapper(),
    );
    gh.factory<_i533.SearchMessageMapper>(() => _i533.SearchMessageMapper());
    gh.factory<_i46.DataExportMessageMapper>(
      () => _i46.DataExportMessageMapper(),
    );
    gh.factory<_i32.DeviceManagementMessageMapper>(
      () => _i32.DeviceManagementMessageMapper(),
    );
    gh.factory<_i468.LlmProviderMessageMapper>(
      () => _i468.LlmProviderMessageMapper(),
    );
    gh.factory<_i614.RecoveryKeyMessageMapper>(
      () => _i614.RecoveryKeyMessageMapper(),
    );
    gh.factory<_i935.WebhookMessageMapper>(() => _i935.WebhookMessageMapper());
    gh.factory<_i862.SyncStatusMessageMapper>(
      () => _i862.SyncStatusMessageMapper(),
    );
    gh.factory<_i1070.TemplateEditorMessageMapper>(
      () => _i1070.TemplateEditorMessageMapper(),
    );
    gh.factory<_i977.DynamicTemplateMessageMapper>(
      () => _i977.DynamicTemplateMessageMapper(),
    );
    gh.factory<_i963.TemplateGeneratorMessageMapper>(
      () => _i963.TemplateGeneratorMessageMapper(),
    );
    gh.factory<_i776.TemplateListMessageMapper>(
      () => _i776.TemplateListMessageMapper(),
    );
    gh.factory<_i467.TemplateSharingExportMessageMapper>(
      () => _i467.TemplateSharingExportMessageMapper(),
    );
    gh.factory<_i166.TemplateSharingImportMessageMapper>(
      () => _i166.TemplateSharingImportMessageMapper(),
    );
    gh.factory<_i804.FeedbackMessageMapper>(
      () => _i804.FeedbackMessageMapper(),
    );
    gh.factory<_i1069.VisualizationMessageMapper>(
      () => _i1069.VisualizationMessageMapper(),
    );
    gh.factory<_i737.IJsExecutor>(() => jsExecutorModule.jsExecutor);
    gh.factory<_i94.HealthSyncMessageMapper>(
      () => _i94.HealthSyncMessageMapper(),
    );
    gh.factory<_i894.AnalysisBuilderMessageMapper>(
      () => _i894.AnalysisBuilderMessageMapper(),
    );
    gh.factory<_i205.ModelRuntimeConverter>(
      () => _i205.ModelRuntimeConverter(),
    );
    gh.factory<_i264.TemplateExceptionMapper>(
      () => _i264.TemplateExceptionMapper(),
    );
    gh.factory<_i303.UnifiedSchemaGenerator>(
      () => _i303.UnifiedSchemaGenerator(),
    );
    gh.factory<_i962.DefaultValueHandler>(() => _i962.DefaultValueHandler());
    gh.factory<_i726.TemplateEditorMessageMapper>(
      () => _i726.TemplateEditorMessageMapper(),
    );
    gh.factory<_i943.ShareableTemplateValidator>(
      () => _i943.ShareableTemplateValidator(),
    );
    gh.factory<_i948.UuidGenerator>(() => _i948.UuidGenerator());
    gh.singleton<_i519.Client>(() => appModule.httpClient);
    gh.singleton<_i711.Client>(() => appModule.serverpodClient);
    gh.singleton<_i75.ThemeService>(() => _i75.ThemeService());
    gh.singleton<_i1024.FontPreloaderService>(
      () => _i1024.FontPreloaderService(),
    );
    gh.lazySingleton<_i174.LocalAuthService>(() => _i174.LocalAuthService());
    gh.lazySingleton<_i557.AppConfig>(() => _i557.AppConfig());
    gh.lazySingleton<_i201.DeviceInfoService>(() => _i201.DeviceInfoService());
    gh.lazySingleton<_i946.PermissionService>(() => _i946.PermissionService());
    gh.lazySingleton<_i171.AppLifecycleService>(
      () => _i171.AppLifecycleService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i548.PlatformCapabilityService>(
      () => _i548.PlatformCapabilityService(),
    );
    gh.lazySingleton<_i189.DatabaseKeyService>(
      () => _i189.DatabaseKeyService(),
    );
    gh.lazySingleton<_i1062.ExternalIntegrationRegistry>(
      () => _i1062.ExternalIntegrationRegistry(),
    );
    gh.lazySingleton<_i419.HealthAdapterFactory>(
      () => _i419.HealthAdapterFactory(),
    );
    gh.lazySingleton<_i763.AdapterRegistry>(() => _i763.AdapterRegistry());
    gh.lazySingleton<_i703.LocalLlmService>(
      () => _i703.LocalLlmService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i531.OcrService>(
      () => _i531.OcrService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i37.RecurrenceService>(() => _i37.RecurrenceService());
    gh.lazySingleton<_i259.SymbolicCombinationGenerator>(
      () => _i259.SymbolicCombinationGenerator(),
    );
    gh.lazySingleton<_i540.WcagComplianceValidatorImpl>(
      () => _i540.WcagComplianceValidatorImpl(),
    );
    gh.lazySingleton<_i496.ShareableTemplateStaging>(
      () => _i496.ShareableTemplateStaging(),
    );
    gh.lazySingleton<_i653.IFeedbackService>(
      () => _i743.ToastFeedbackService(),
    );
    gh.factory<_i866.IUnitService>(() => _i866.UnitService());
    gh.lazySingleton<_i653.ILoadingService>(() => _i1002.LoadingService());
    gh.lazySingleton<_i653.ILocalizationService>(
      () => _i946.AppLocalizationService(),
    );
    gh.singleton<_i475.IPowerSyncRepository>(
      () => _i475.PowerSyncRepository(gh<_i189.DatabaseKeyService>()),
    );
    gh.factory<_i399.TemplateExportService>(
      () => _i399.TemplateExportService(gh<_i810.IAnalysisScriptRepository>()),
    );
    gh.lazySingleton<_i880.IHapticFeedbackService>(
      () => _i880.HapticFeedbackService(),
    );
    gh.factory<_i499.INetworkRepository>(
      () => _i499.NetworkRepository(gh<_i519.Client>()),
    );
    gh.lazySingleton<_i653.IExceptionKeyMapper>(
      () => _i620.QuanityaExceptionKeyMapper(),
    );
    gh.factory<_i953.JsonToModelParser>(
      () => _i953.JsonToModelParser(
        gh<_i540.WcagComplianceValidatorImpl>(),
        gh<_i962.DefaultValueHandler>(),
      ),
    );
    gh.factory<_i726.TemplateCatalogService>(
      () => _i726.TemplateCatalogService(
        gh<_i519.Client>(),
        gh<_i557.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i618.CalculationService>(
      () => _i618.CalculationService(gh<_i679.CalculationRepository>()),
    );
    await gh.singletonAsync<_i147.AppDatabase>(
      () => appModule.getDatabase(gh<_i475.IPowerSyncRepository>()),
      preResolve: true,
    );
    gh.lazySingleton<_i62.AppSyncingRepository>(
      () => _i62.AppSyncingRepository(
        gh<_i147.AppDatabase>(),
        gh<_i557.AppConfig>(),
      ),
    );
    gh.factory<_i1027.PairingQrMessageMapper>(
      () => _i1027.PairingQrMessageMapper(gh<_i653.IExceptionKeyMapper>()),
    );
    gh.factory<_i1027.PairingScanMessageMapper>(
      () => _i1027.PairingScanMessageMapper(gh<_i653.IExceptionKeyMapper>()),
    );
    gh.lazySingleton<_i83.ISecureStorage>(
      () => _i1035.PlatformSecureStorage(gh<_i548.PlatformCapabilityService>()),
    );
    gh.lazySingleton<_i246.KeyExportService>(
      () => _i246.KeyExportService(gh<_i83.ISecureStorage>()),
    );
    gh.factory<_i195.TemplateSharingExportCubit>(
      () => _i195.TemplateSharingExportCubit(gh<_i399.TemplateExportService>()),
    );
    gh.factory<_i808.AiTemplateGenerator>(
      () => _i808.AiTemplateGenerator(
        gh<_i259.SymbolicCombinationGenerator>(),
        gh<_i303.UnifiedSchemaGenerator>(),
      ),
    );
    gh.factory<_i560.PlatformLocalAuth>(
      () => _i560.PlatformLocalAuth(gh<_i548.PlatformCapabilityService>()),
    );
    gh.lazySingleton<_i453.ICrossDeviceKeyStorage>(
      () => crossDeviceKeyModule.crossDeviceStorage(gh<_i83.ISecureStorage>()),
    );
    gh.lazySingleton<_i145.AnalysisScriptQueryDao>(
      () => _i145.AnalysisScriptQueryDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i302.AnalyticsInboxDao>(
      () => _i302.AnalyticsInboxDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i292.ErrorBoxDao>(
      () => _i292.ErrorBoxDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i523.FtsSearchDao>(
      () => _i523.FtsSearchDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i95.LogEntryQueryDao>(
      () => _i95.LogEntryQueryDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i702.NotificationDao>(
      () => _i702.NotificationDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i318.ScheduleQueryDao>(
      () => _i318.ScheduleQueryDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i870.TemplateQueryDao>(
      () => _i870.TemplateQueryDao(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i198.DataExportRepository>(
      () => _i198.DataExportRepository(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i872.LlmProviderConfigRepository>(
      () => _i872.LlmProviderConfigRepository(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i504.OpenRouterModelRepository>(
      () => _i504.OpenRouterModelRepository(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i305.WebhookRepository>(
      () => _i305.WebhookRepository(gh<_i147.AppDatabase>()),
    );
    gh.lazySingleton<_i788.SecurePreferences>(
      () => _i788.SecurePreferences(gh<_i83.ISecureStorage>()),
    );
    gh.lazySingleton<_i132.ApiKeyRepository>(
      () => _i132.ApiKeyRepository(
        gh<_i147.AppDatabase>(),
        gh<_i83.ISecureStorage>(),
      ),
    );
    gh.lazySingleton<_i515.AuthRepository>(
      () => _i515.AuthRepository(
        gh<_i788.SecurePreferences>(),
        gh<_i83.ISecureStorage>(),
      ),
    );
    gh.factory<_i632.DataExportCubit>(
      () => _i632.DataExportCubit(gh<_i198.DataExportRepository>()),
    );
    gh.lazySingleton<_i932.HiddenVisibilityCubit>(
      () => _i932.HiddenVisibilityCubit(
        gh<_i560.PlatformLocalAuth>(),
        gh<_i653.ILocalizationService>(),
      ),
    );
    gh.lazySingleton<_i867.ErrorBoxRepository>(
      () => _i867.ErrorBoxRepository(gh<_i292.ErrorBoxDao>()),
    );
    gh.lazySingleton<_i558.FtsSearchRepository>(
      () => _i558.FtsSearchRepository(
        gh<_i523.FtsSearchDao>(),
        gh<_i95.LogEntryQueryDao>(),
      ),
    );
    gh.lazySingleton<_i922.GuidedTourService>(
      () => _i922.GuidedTourService(gh<_i788.SecurePreferences>()),
    );
    gh.lazySingleton<_i884.EntitlementRepository>(
      () => _i884.EntitlementRepository(gh<_i788.SecurePreferences>()),
    );
    gh.lazySingleton<_i709.TestedModelsService>(
      () => _i709.TestedModelsService(
        gh<_i504.OpenRouterModelRepository>(),
        gh<_i872.LlmProviderConfigRepository>(),
        gh<_i519.Client>(),
      ),
    );
    gh.lazySingleton<_i155.LlmProviderCubit>(
      () => _i155.LlmProviderCubit(
        gh<_i872.LlmProviderConfigRepository>(),
        gh<_i504.OpenRouterModelRepository>(),
        gh<_i132.ApiKeyRepository>(),
        gh<_i709.TestedModelsService>(),
        gh<_i519.Client>(),
      ),
    );
    gh.lazySingleton<_i367.ICryptoKeyRepository>(
      () => _i367.CryptoKeyRepository(
        gh<_i83.ISecureStorage>(),
        gh<_i453.ICrossDeviceKeyStorage>(),
      ),
    );
    gh.factory<_i549.IDataEncryption>(
      () => _i549.DataEncryption(gh<_i367.ICryptoKeyRepository>()),
    );
    gh.factory<_i404.SearchCubit>(
      () => _i404.SearchCubit(gh<_i558.FtsSearchRepository>()),
    );
    gh.lazySingleton<_i41.NotificationRepository>(
      () => _i41.NotificationRepository(gh<_i702.NotificationDao>()),
    );
    gh.lazySingleton<_i401.AccountService>(
      () => _i401.AccountService(
        gh<_i515.AuthRepository>(),
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i549.IDataEncryption>(),
        gh<_i711.Client>(),
        gh<_i83.ISecureStorage>(),
      ),
    );
    gh.factory<_i576.DeviceManagementCubit>(
      () => _i576.DeviceManagementCubit(
        gh<_i401.AccountService>(),
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i201.DeviceInfoService>(),
      ),
    );
    gh.lazySingleton<_i494.PublicSubmissionService>(
      () => _i494.PublicSubmissionService(
        gh<_i711.Client>(),
        gh<_i367.ICryptoKeyRepository>(),
      ),
    );
    gh.factory<_i831.NoticesCubit>(
      () => _i831.NoticesCubit(gh<_i41.NotificationRepository>()),
    );
    gh.lazySingleton<_i156.IE2EEPuller>(
      () => _i156.E2EEPuller(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.lazySingleton<_i71.AuthService>(
      () => _i71.AuthService(
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i549.IDataEncryption>(),
        gh<_i711.Client>(),
        gh<_i788.SecurePreferences>(),
      ),
    );
    gh.lazySingleton<_i581.WebhookService>(
      () => _i581.WebhookService(
        gh<_i305.WebhookRepository>(),
        gh<_i132.ApiKeyRepository>(),
        gh<_i519.Client>(),
      ),
    );
    gh.lazySingleton<_i743.AnalyticsInboxRepository>(
      () => _i743.AnalyticsInboxRepository(gh<_i302.AnalyticsInboxDao>()),
    );
    gh.factory<_i939.FieldShapeResolver>(
      () => _i939.FieldShapeResolver(gh<_i870.TemplateQueryDao>()),
    );
    gh.lazySingleton<_i404.AccountInfoCubit>(
      () => _i404.AccountInfoCubit(gh<_i71.AuthService>()),
    );
    gh.lazySingleton<_i258.IPairingService>(
      () => _i258.PairingService(
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i549.IDataEncryption>(),
        gh<_i711.Client>(),
        gh<_i62.AppSyncingRepository>(),
      ),
    );
    gh.lazySingleton<_i7.AuthAccountOrchestrator>(
      () => _i7.AuthAccountOrchestrator(
        gh<_i71.AuthService>(),
        gh<_i401.AccountService>(),
      ),
    );
    gh.factory<_i1000.PairingQrCubit>(
      () => _i1000.PairingQrCubit(gh<_i258.IPairingService>()),
    );
    gh.factory<_i813.PairingScanCubit>(
      () => _i813.PairingScanCubit(gh<_i258.IPairingService>()),
    );
    gh.lazySingleton<_i985.AnalyticsService>(
      () => _i985.AnalyticsService(
        gh<_i711.Client>(),
        gh<_i743.AnalyticsInboxRepository>(),
        gh<_i494.PublicSubmissionService>(),
      ),
    );
    gh.lazySingleton<_i984.DeleteOrchestrator>(
      () => _i984.DeleteOrchestrator(
        gh<_i401.AccountService>(),
        gh<_i515.AuthRepository>(),
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i884.EntitlementRepository>(),
        gh<_i475.IPowerSyncRepository>(),
        gh<_i156.IE2EEPuller>(),
        gh<_i922.GuidedTourService>(),
        gh<_i711.Client>(),
        gh<_i189.DatabaseKeyService>(),
        gh<_i246.KeyExportService>(),
      ),
    );
    gh.factory<_i177.OnboardingCubit>(
      () => _i177.OnboardingCubit(
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i246.KeyExportService>(),
        gh<_i560.PlatformLocalAuth>(),
        gh<_i401.AccountService>(),
        gh<_i201.DeviceInfoService>(),
      ),
    );
    gh.lazySingleton<_i636.IEntitlementService>(
      () => _i695.EntitlementService(
        gh<_i711.Client>(),
        gh<_i7.AuthAccountOrchestrator>(),
        gh<_i884.EntitlementRepository>(),
      ),
    );
    gh.lazySingleton<_i851.SyncService>(
      () => _i851.SyncService(
        gh<_i475.IPowerSyncRepository>(),
        gh<_i62.AppSyncingRepository>(),
        gh<_i884.EntitlementRepository>(),
        gh<_i7.AuthAccountOrchestrator>(),
        gh<_i156.IE2EEPuller>(),
        gh<_i499.INetworkRepository>(),
        gh<_i557.AppConfig>(),
        gh<_i711.Client>(),
      ),
    );
    gh.lazySingleton<_i426.IPurchaseService>(
      () => _i163.PurchaseService(
        gh<_i494.PublicSubmissionService>(),
        gh<_i711.Client>(),
        gh<_i548.PlatformCapabilityService>(),
        gh<_i884.EntitlementRepository>(),
      ),
    );
    gh.lazySingleton<_i50.EntitlementCubit>(
      () => _i50.EntitlementCubit(
        gh<_i636.IEntitlementService>(),
        gh<_i884.EntitlementRepository>(),
        gh<_i147.AppDatabase>(),
        gh<_i515.AuthRepository>(),
      ),
    );
    gh.factory<_i431.WebhookCubit>(
      () => _i431.WebhookCubit(
        gh<_i305.WebhookRepository>(),
        gh<_i132.ApiKeyRepository>(),
        gh<_i581.WebhookService>(),
      ),
    );
    gh.factory<_i886.AnalysisScriptDualDao>(
      () => _i886.AnalysisScriptDualDao(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.lazySingleton<_i896.LogEntryDualDao>(
      () => _i896.LogEntryDualDao(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.lazySingleton<_i233.ScheduleDualDao>(
      () => _i233.ScheduleDualDao(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.lazySingleton<_i14.TemplateAestheticsDualDao>(
      () => _i14.TemplateAestheticsDualDao(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.lazySingleton<_i285.TrackerTemplateDualDao>(
      () => _i285.TrackerTemplateDualDao(
        gh<_i147.AppDatabase>(),
        gh<_i549.IDataEncryption>(),
      ),
    );
    gh.factory<_i65.RecoveryKeyCubit>(
      () => _i65.RecoveryKeyCubit(gh<_i401.AccountService>()),
    );
    gh.factory<_i341.AnalyticsCubit>(
      () => _i341.AnalyticsCubit(
        gh<_i743.AnalyticsInboxRepository>(),
        gh<_i985.AnalyticsService>(),
        gh<_i62.AppSyncingRepository>(),
      ),
    );
    gh.lazySingleton<
      _i670.DualDao<_i147.TrackerTemplate, _i147.EncryptedTemplate>
    >(
      () =>
          appModule.trackerTemplateDualDao(gh<_i285.TrackerTemplateDualDao>()),
    );
    gh.lazySingleton<_i160.PurchaseCubit>(
      () => _i160.PurchaseCubit(gh<_i426.IPurchaseService>()),
    );
    gh.lazySingleton<_i106.ErrorReporterService>(
      () => _i106.ErrorReporterService(
        gh<_i711.Client>(),
        gh<_i494.PublicSubmissionService>(),
      ),
    );
    gh.lazySingleton<_i277.FeedbackSubmissionService>(
      () => _i277.FeedbackSubmissionService(
        gh<_i711.Client>(),
        gh<_i494.PublicSubmissionService>(),
      ),
    );
    gh.lazySingleton<_i407.AppSyncingCubit>(
      () => _i407.AppSyncingCubit(
        gh<_i62.AppSyncingRepository>(),
        gh<_i851.SyncService>(),
      ),
    );
    gh.lazySingleton<_i562.ErrorsCubit>(
      () => _i562.ErrorsCubit(
        gh<_i867.ErrorBoxRepository>(),
        gh<_i106.ErrorReporterService>(),
        gh<_i62.AppSyncingRepository>(),
      ),
    );
    gh.factory<_i714.FeedbackCubit>(
      () => _i714.FeedbackCubit(gh<_i277.FeedbackSubmissionService>()),
    );
    gh.factory<_i34.ILogEntryRepository>(
      () => _i328.LogEntryRepository(
        gh<_i896.LogEntryDualDao>(),
        gh<_i95.LogEntryQueryDao>(),
        gh<_i870.TemplateQueryDao>(),
        gh<_i147.AppDatabase>(),
      ),
    );
    gh.lazySingleton<_i723.ScheduleRepository>(
      () => _i723.ScheduleRepository(
        gh<_i233.ScheduleDualDao>(),
        gh<_i318.ScheduleQueryDao>(),
      ),
    );
    gh.factory<_i39.EntryDetailCubit>(
      () => _i39.EntryDetailCubit(
        gh<_i95.LogEntryQueryDao>(),
        gh<_i34.ILogEntryRepository>(),
      ),
    );
    gh.lazySingleton<_i637.LlmService>(
      () => _i637.LlmService(
        gh<_i519.Client>(),
        gh<_i711.Client>(),
        gh<_i7.AuthAccountOrchestrator>(),
      ),
    );
    gh.lazySingleton<_i25.SyncStatusCubit>(
      () => _i25.SyncStatusCubit(
        gh<_i475.IPowerSyncRepository>(),
        gh<_i851.SyncService>(),
      ),
    );
    gh.lazySingleton<_i190.IDigitalPurchaseRepository>(
      () => _i59.InAppPurchaseRepository(
        gh<_i711.Client>(),
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i549.IDataEncryption>(),
        gh<_i7.AuthAccountOrchestrator>(),
      ),
    );
    gh.factory<_i386.TimelineDataCubit>(
      () => _i386.TimelineDataCubit(
        gh<_i34.ILogEntryRepository>(),
        gh<_i870.TemplateQueryDao>(),
      ),
    );
    gh.lazySingleton<_i75.DataIngestionService>(
      () => _i75.DataIngestionService(
        gh<_i763.AdapterRegistry>(),
        gh<_i34.ILogEntryRepository>(),
      ),
    );
    gh.factory<_i874.ImportExecutor>(
      () => _i874.ImportExecutor(gh<_i75.DataIngestionService>()),
    );
    gh.factory<_i790.AiAnalysisOrchestrator>(
      () => _i790.AiAnalysisOrchestrator(gh<_i637.LlmService>()),
    );
    gh.factory<_i810.IAnalysisScriptRepository>(
      () => _i141.AnalysisScriptRepository(
        gh<_i886.AnalysisScriptDualDao>(),
        gh<_i145.AnalysisScriptQueryDao>(),
        gh<_i95.LogEntryQueryDao>(),
        gh<_i870.TemplateQueryDao>(),
      ),
    );
    gh.lazySingleton<_i554.TemplateWithAestheticsRepository>(
      () => repositoryModule.templateWithAestheticsRepo(
        gh<_i670.DualDao<_i147.TrackerTemplate, _i147.EncryptedTemplate>>(),
        gh<_i14.TemplateAestheticsDualDao>(),
        gh<_i870.TemplateQueryDao>(),
        gh<_i305.WebhookRepository>(),
      ),
    );
    gh.factory<_i193.IWasmAnalysisService>(
      () => _i193.WasmAnalysisService(
        gh<_i810.IAnalysisScriptRepository>(),
        gh<_i737.IJsExecutor>(),
      ),
    );
    gh.lazySingleton<_i306.LogEntryService>(
      () => _i306.LogEntryService(
        gh<_i34.ILogEntryRepository>(),
        gh<_i581.WebhookService>(),
      ),
    );
    gh.factory<_i294.LlmChatService>(
      () => _i294.LlmChatService(gh<_i637.LlmService>()),
    );
    gh.factory<_i670.AiTemplateOrchestrator>(
      () => _i670.AiTemplateOrchestrator(
        gh<_i637.LlmService>(),
        gh<_i953.JsonToModelParser>(),
        gh<_i808.AiTemplateGenerator>(),
      ),
    );
    gh.factory<_i867.AiTemplateService>(
      () => _i867.AiTemplateService(
        gh<_i637.LlmService>(),
        gh<_i953.JsonToModelParser>(),
        gh<_i808.AiTemplateGenerator>(),
      ),
    );
    gh.factory<_i143.ImportCubit>(
      () => _i143.ImportCubit(
        gh<_i531.OcrService>(),
        gh<_i703.LocalLlmService>(),
        gh<_i874.ImportExecutor>(),
      ),
    );
    gh.lazySingleton<_i746.HealthSyncService>(
      () => _i746.HealthSyncService(
        gh<_i419.HealthAdapterFactory>(),
        gh<_i75.DataIngestionService>(),
        gh<_i870.TemplateQueryDao>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i788.SecurePreferences>(),
        gh<_i171.AppLifecycleService>(),
      ),
    );
    gh.factory<_i839.DynamicTemplateCubit>(
      () => _i839.DynamicTemplateCubit(
        gh<_i306.LogEntryService>(),
        gh<_i962.DefaultValueHandler>(),
      ),
    );
    gh.lazySingleton<_i886.INotificationActionHandler>(
      () => _i886.NotificationActionHandler(
        gh<_i306.LogEntryService>(),
        gh<_i34.ILogEntryRepository>(),
        gh<_i870.TemplateQueryDao>(),
      ),
    );
    gh.factory<_i966.TemplateListCubit>(
      () => _i966.TemplateListCubit(
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i306.LogEntryService>(),
      ),
    );
    gh.factory<_i824.TemplateGalleryCubit>(
      () => _i824.TemplateGalleryCubit(
        gh<_i726.TemplateCatalogService>(),
        gh<_i496.ShareableTemplateStaging>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i810.IAnalysisScriptRepository>(),
      ),
    );
    gh.factory<_i648.TemplateImportService>(
      () => _i648.TemplateImportService(
        gh<_i519.Client>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i810.IAnalysisScriptRepository>(),
      ),
    );
    gh.factory<_i135.TemplateGeneratorCubit>(
      () => _i135.TemplateGeneratorCubit(
        gh<_i670.AiTemplateOrchestrator>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
      ),
    );
    gh.lazySingleton<_i825.DataRetrievalService>(
      () => _i825.DataRetrievalService(
        gh<_i95.LogEntryQueryDao>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i618.CalculationService>(),
      ),
    );
    gh.factory<_i820.AnalysisEngine>(
      () => _i820.AnalysisEngine(gh<_i193.IWasmAnalysisService>()),
    );
    gh.lazySingleton<_i330.DevSeederService>(
      () => _i330.DevSeederService(
        gh<_i147.AppDatabase>(),
        gh<_i367.ICryptoKeyRepository>(),
        gh<_i896.LogEntryDualDao>(),
        gh<_i496.ShareableTemplateStaging>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i810.IAnalysisScriptRepository>(),
      ),
      registerFor: {_dev},
    );
    gh.factory<_i676.ResultsListCubit>(
      () => _i676.ResultsListCubit(
        gh<_i34.ILogEntryRepository>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
      ),
    );
    gh.factory<_i611.HealthSyncCubit>(
      () => _i611.HealthSyncCubit(
        gh<_i746.HealthSyncService>(),
        gh<_i946.PermissionService>(),
      ),
    );
    gh.factory<_i831.VisualizationCubit>(
      () => _i831.VisualizationCubit(
        gh<_i825.DataRetrievalService>(),
        gh<_i810.IAnalysisScriptRepository>(),
        gh<_i820.AnalysisEngine>(),
      ),
    );
    gh.lazySingleton<_i42.NotificationService>(
      () => _i42.NotificationService(gh<_i886.INotificationActionHandler>()),
    );
    gh.factory<_i60.StreamingAnalyticsService>(
      () => _i60.StreamingAnalyticsService(
        gh<_i810.IAnalysisScriptRepository>(),
        gh<_i820.AnalysisEngine>(),
        gh<_i34.ILogEntryRepository>(),
      ),
    );
    gh.factory<_i77.TemplateSharingImportCubit>(
      () => _i77.TemplateSharingImportCubit(gh<_i648.TemplateImportService>()),
    );
    gh.factory<_i873.AnalysisBuilderCubit>(
      () => _i873.AnalysisBuilderCubit(
        gh<_i810.IAnalysisScriptRepository>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i790.AiAnalysisOrchestrator>(),
        gh<_i939.FieldShapeResolver>(),
        gh<_i60.StreamingAnalyticsService>(),
        gh<_i193.IWasmAnalysisService>(),
      ),
    );
    gh.factory<_i753.PlatformNotificationService>(
      () => _i753.PlatformNotificationService(
        gh<_i548.PlatformCapabilityService>(),
        gh<_i42.NotificationService>(),
      ),
    );
    gh.lazySingleton<_i840.ScheduleGeneratorService>(
      () => _i840.ScheduleGeneratorService(
        gh<_i723.ScheduleRepository>(),
        gh<_i34.ILogEntryRepository>(),
        gh<_i37.RecurrenceService>(),
        gh<_i42.NotificationService>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
      ),
    );
    gh.lazySingleton<_i909.ScheduleService>(
      () => _i909.ScheduleService(
        gh<_i723.ScheduleRepository>(),
        gh<_i840.ScheduleGeneratorService>(),
      ),
    );
    gh.factory<_i291.TemplateEditorCubit>(
      () => _i291.TemplateEditorCubit(
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i723.ScheduleRepository>(),
        gh<_i946.PermissionService>(),
        gh<_i909.ScheduleService>(),
        gh<_i496.ShareableTemplateStaging>(),
        gh<_i810.IAnalysisScriptRepository>(),
      ),
    );
    gh.factory<_i436.ScheduleListCubit>(
      () => _i436.ScheduleListCubit(
        gh<_i723.ScheduleRepository>(),
        gh<_i554.TemplateWithAestheticsRepository>(),
        gh<_i909.ScheduleService>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i1028.AppModule {}

class _$JsExecutorModule extends _i777.JsExecutorModule {}

class _$CrossDeviceKeyModule extends _i29.CrossDeviceKeyModule {}

class _$RepositoryModule extends _i1028.RepositoryModule {}
