import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// General-purpose app lifecycle hook registry.
///
/// Services register named callbacks that fire on app resume.
/// Each callback is fire-and-forget — one failure doesn't block others.
///
/// Example:
/// ```dart
/// getIt<AppLifecycleService>().registerOnResume(
///   'health_sync',
///   () => healthSyncService.syncIfEnabled(),
/// );
/// ```
@lazySingleton
class AppLifecycleService {
  final Map<String, Future<void> Function()> _onResumeCallbacks = {};
  AppLifecycleListener? _listener;

  /// Call from the root widget's initState to start listening.
  void init() {
    _listener = AppLifecycleListener(onResume: _handleResume);
  }

  void registerOnResume(String key, Future<void> Function() callback) {
    _onResumeCallbacks[key] = callback;
  }

  void unregisterOnResume(String key) {
    _onResumeCallbacks.remove(key);
  }

  void _handleResume() {
    for (final entry in _onResumeCallbacks.entries) {
      entry.value().catchError((e) {
        debugPrint('AppLifecycleService: ${entry.key} onResume failed: $e');
      });
    }
  }

  @disposeMethod
  void dispose() {
    _listener?.dispose();
    _onResumeCallbacks.clear();
  }
}
