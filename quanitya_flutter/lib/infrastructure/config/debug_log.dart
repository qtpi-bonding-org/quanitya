import 'package:flutter/foundation.dart' show debugPrint;

/// Per-file debug logging with central toggle.
///
/// Usage in any file:
/// ```dart
/// const _tag = 'powersync_service';
/// // ...
/// Log.d(_tag, '🔌 connect: ps_crud count = 0');
/// ```
///
/// Toggle files on/off below. Uses debugPrint internally —
/// compiles to nothing in release builds.
class Log {
  Log._();

  static void d(String tag, String msg) {
    if (_enabled[tag] ?? false) debugPrint(msg);
  }

  static const _enabled = <String, bool>{
    // Sync
    'powersync_service': true,
    'sync_service': true,
    'e2ee_puller': false,

    // Auth
    'auth_orchestrator': true,
    'auth_service': false,
    'account_service': true,
    'delete_orchestrator': true,

    // Purchase
    'entitlement_service': false,
    'purchase_repository': false,

    // AI / LLM
    'llm_service': true,
    'ai_analysis_orchestrator': true,
    'field_shape_resolver': true,

    // Device pairing
    'pairing_service': false,
  };
}
