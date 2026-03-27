import 'package:flutter/foundation.dart' show debugPrint;

/// Per-file debug logging with central toggle.
///
/// Tags are lib-relative file paths without extension:
/// ```dart
/// const _tag = 'data/sync/powersync_service'; // lib-relative, no .dart
/// Log.d(_tag, '🔌 connect: ps_crud count = 0');
/// ```
///
/// Files not listed in [_enabled] fall back to [_defaultEnabled].
/// Flip [_defaultEnabled] to `true` to see everything, then selectively
/// silence noisy files via `false` overrides.
///
/// Uses debugPrint internally — compiles to nothing in release builds.
class Log {
  Log._();

  static const _defaultEnabled = false;

  static void d(String tag, String msg) {
    if (_enabled[tag] ?? _defaultEnabled) debugPrint(msg);
  }

  static const _enabled = <String, bool>{
    // App
    'main': false,
    'app/bootstrap': false,
    'app/app_module': false,
    'app_router': false,

    // Data
    'data/dao/dual_dao': false,
    'data/dao/fts_search_dao': false,
    'data/repositories/data_export_repository': false,
    'data/repositories/e2ee_puller': false,
    'data/sync/powersync_service': true,

    // Sync
    'infrastructure/sync/sync_service': true,

    // Auth
    'infrastructure/auth/auth_account_orchestrator': true,
    'infrastructure/auth/account_service': true,
    'infrastructure/auth/delete_orchestrator': true,

    // Platform
    'infrastructure/platform/app_lifecycle_service': false,
    'infrastructure/platform/platform_local_auth': false,
    'infrastructure/platform/platform_notification_service': false,
    'infrastructure/platform/platform_secure_storage': false,
    'infrastructure/device/device_info_service': false,
    'infrastructure/permissions/permission_service': false,

    // Feedback & errors
    'infrastructure/feedback/feedback_service': false,
    'infrastructure/feedback/loading_service': false,
    'infrastructure/error_reporting/error_reporter_service': false,
    'infrastructure/core/try_operation': false,
    'infrastructure/fonts/font_preloader_service': false,

    // Notifications
    'infrastructure/notifications/notification_service': false,
    'infrastructure/notifications/notification_action_handler': false,

    // Purchase
    'infrastructure/purchase/entitlement_service': false,
    'infrastructure/purchase/purchase_service': false,
    'infrastructure/purchase/providers/in_app_purchase_repository': false,

    // AI / LLM
    'infrastructure/llm/services/llm_service': true,
    'logic/llm/services/local_llm_service': false,
    'logic/analysis/services/ai/ai_analysis_orchestrator': true,
    'logic/analysis/services/field_shape_resolver': true,
    'logic/analysis/services/wasm_analysis_service': false,
    'logic/ocr/services/ocr_service': false,

    // Schedules
    'logic/schedules/services/recurrence_service': false,
    'logic/schedules/services/schedule_generator_service': false,

    // Templates
    'logic/templates/services/engine/json_to_model_parser': false,

    // Analytics & webhooks
    'logic/analytics/analytics_service': false,
    'infrastructure/webhooks/webhook_service': false,
    'infrastructure/public_submission/public_submission_service': false,

    // Integrations
    'integrations/flutter/health/health_sync_service': false,

    // Features — device pairing
    'features/device_pairing/services/pairing_service': false,
    'features/device_pairing/cubits/pairing_qr_cubit': false,
    'features/device_pairing/cubits/pairing_scan_cubit': false,

    // Features — purchase
    'features/purchase/cubits/entitlement_cubit': false,
    'features/purchase/cubits/purchase_cubit': false,

    // Features — other
    'features/app_syncing_mode/repositories/app_syncing_repository': false,
    'features/errors/cubits/errors_cubit': false,
    'features/home/cubits/timeline_data_cubit': false,
    'features/log_entry/cubits/import/import_cubit': false,
    'features/settings/pages/settings_page': false,
    'features/visualization/cubits/visualization_cubit': false,

    // Dev
    'dev/pages/ocr_test_page': false,
    'dev/services/dev_seeder_service': false,
  };
}
