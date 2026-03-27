import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import '../../infrastructure/config/debug_log.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../../data/repositories/analytics_inbox_repository.dart';
import '../../infrastructure/public_submission/public_submission_service.dart';

const _tag = 'logic/analytics/analytics_service';

/// Privacy-first analytics service with local-first storage.
///
/// All events are saved to the local analytics inbox first.
/// Events are only sent to the server when:
/// - Auto-send is enabled (batch-sent on app startup)
/// - User manually triggers send from the analytics inbox UI
///
/// Tracking methods are fire-and-forget — they never throw or block.
@lazySingleton
class AnalyticsService {
  final Client _client;
  final AnalyticsInboxRepository _inbox;
  final PublicSubmissionService _submissionService;

  AnalyticsService(this._client, this._inbox, this._submissionService);

  // ── Template lifecycle ──
  void trackTemplateCreated() => _track('template_created');
  void trackTemplateDeleted() => _track('template_deleted');

  // ── Logging ──
  void trackEntryLogged() => _track('entry_logged');
  void trackQuickLog() => _track('quick_log');

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

  // ── Onboarding ──
  void trackAccountCreated() => _track('account_created');

  // ── Sync ──
  void trackSyncModeChanged() => _track('sync_mode_changed');

  // ── Devices ──
  void trackDevicePaired() => _track('device_paired');
  void trackDeviceRevoked() => _track('device_revoked');

  // ── Security ──
  void trackRecoveryKeyViewed() => _track('recovery_key_viewed');

  // ── Webhooks ──
  void trackWebhookCreated() => _track('webhook_created');
  void trackWebhookDeleted() => _track('webhook_deleted');

  // ── LLM ──
  void trackLlmConfigured() => _track('llm_configured');

  // ── App lifecycle ──
  void trackAppOpened() => _track('app_opened');

  // ── Feedback ──
  void trackFeedbackSubmitted() => _track('feedback_submitted');

  // ── Catalog ──
  void trackCatalogTemplatesImported() => _track('catalog_templates_imported');

  // ── Search ──
  void trackSearchPerformed() => _track('search_performed');

  // ── Purchase ──
  void trackPurchaseCompleted({required String productId}) {
    _track('purchase_completed', props: {'product_id': productId});
  }

  /// Save event to local inbox. Never throws.
  void _track(String event, {Map<String, dynamic>? props}) {
    Log.d(_tag, 'Analytics: tracking "$event"');
    unawaited(_inbox.saveEvent(
      eventName: event,
      clientTimestamp: DateTime.now().toUtc(),
      platform: _platformName,
      props: props != null ? jsonEncode(props) : null,
    ).then((_) {
      Log.d(_tag, 'Analytics: "$event" saved to inbox');
    }).catchError((e) {
      Log.d(_tag, 'Analytics: "$event" FAILED: $e');
    }));
  }

  /// Batch-send all unsent events to the server.
  ///
  /// Sends in chunks of 100. Each chunk is sent with a single
  /// PoW + ECDSA verification for spam prevention.
  /// Returns the number of events successfully sent.
  Future<int> sendAllUnsent() async {
    final allEvents = await _inbox.getUnsentEvents();
    if (allEvents.isEmpty) return 0;

    var totalSent = 0;

    // Send in chunks of 100
    for (var i = 0; i < allEvents.length; i += 100) {
      final batch = allEvents.sublist(
        i,
        i + 100 > allEvents.length ? allEvents.length : i + 100,
      );

      try {
        // Serialize batch to JSON
        final eventsJson = jsonEncode(
          batch.map((e) => {
            'eventName': e.eventName,
            'clientTimestamp': e.clientTimestamp.toIso8601String(),
            'platform': e.platform,
            'props': e.props,
          }).toList(),
        );

        // Build payload suffix for signing: "analytics:{count}"
        final payloadSuffix = 'analytics:${batch.length}';

        // Submit via PublicSubmissionService (challenge + PoW + signature)
        await _submissionService.submitWithVerification(
          endpoint: 'analyticsEvent',
          payload: payloadSuffix,
          submitCallback: (challenge, proofOfWork, publicKeyHex, signature) async {
            await _client.analyticsEvent.submitEvents(
              challenge: challenge,
              proofOfWork: proofOfWork,
              publicKeyHex: publicKeyHex,
              signature: signature,
              eventsJson: eventsJson,
            );
          },
        );

        totalSent += batch.length;
      } catch (e, stack) {
        Log.d(_tag, 'Analytics batch send error: $e');
        await ErrorPrivserver.captureError(e, stack, source: 'AnalyticsService');
        break;
      }
    }

    return totalSent;
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
