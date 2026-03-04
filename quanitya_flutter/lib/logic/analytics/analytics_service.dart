import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

/// Privacy-first analytics service backed by Serverpod + Postgres.
///
/// All tracking methods are fire-and-forget — they never throw or block.
/// If the server is unreachable (e.g. local-only mode), calls silently no-op.
@lazySingleton
class AnalyticsService {
  final Client _client;

  AnalyticsService(this._client);

  // ── Template lifecycle ──
  void trackTemplateCreated() => _track('template_created');
  void trackTemplateDeleted() => _track('template_deleted');

  // ── Logging ──
  void trackEntryLogged() => _track('entry_logged');

  // ── Sharing ──
  void trackTemplateExported() => _track('template_exported');
  void trackTemplateImported() => _track('template_imported');

  // ── Analytics / Pipelines ──
  void trackAnalysisRun() => _track('analysis_run');

  // ── Schedules ──
  void trackScheduleCreated() => _track('schedule_created');

  // ── Health ──
  void trackHealthSynced() => _track('health_synced');

  // ── Data ──
  void trackDataExported() => _track('data_exported');
  void trackDataImported() => _track('data_imported');

  // ── App lifecycle ──
  void trackAppOpened() => _track('app_opened');

  // ── Purchase ──
  void trackPurchaseCompleted({required String productId}) {
    _track('purchase_completed', props: {'product_id': productId});
  }

  void _track(String event, {Map<String, dynamic>? props}) {
    try {
      _client.analyticsEvent
          .submitEvent(
            eventName: event,
            clientTimestamp: DateTime.now().toUtc(),
            platform: _platformName,
            props: props != null ? jsonEncode(props) : null,
          )
          .catchError((_) {});
    } catch (_) {
      // Silently swallow sync errors (e.g. client not connected).
    }
  }

  static String? get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return null;
  }
}
