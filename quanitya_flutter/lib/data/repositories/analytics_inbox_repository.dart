import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';

import '../dao/analytics_inbox_dao.dart';
import '../db/app_database.dart';

/// Exception type for analytics inbox operations.
class AnalyticsInboxException implements Exception {
  final String message;
  final Object? cause;

  const AnalyticsInboxException(this.message, [this.cause]);

  @override
  String toString() => 'AnalyticsInboxException: $message';
}

/// Repository for analytics inbox operations.
///
/// Wraps DAO with tryMethod for consistent exception handling.
/// Provides streaming access to locally-stored analytics events.
@lazySingleton
class AnalyticsInboxRepository {
  final AnalyticsInboxDao _dao;

  AnalyticsInboxRepository(this._dao);

  // ─────────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Store a new analytics event locally
  Future<void> saveEvent({
    required String eventName,
    required DateTime clientTimestamp,
    String? platform,
    String? props,
  }) {
    return tryMethod(() async {
      await _dao.insertEvent(
        eventName: eventName,
        clientTimestamp: clientTimestamp,
        platform: platform,
        props: props,
      );
    }, AnalyticsInboxException.new, 'saveEvent');
  }

  /// Mark events as sent
  Future<void> markAsSent(List<int> ids) {
    return tryMethod(() async {
      await _dao.markAsSent(ids);
    }, AnalyticsInboxException.new, 'markAsSent');
  }

  /// Clear all sent events
  Future<void> clearSentEvents() {
    return tryMethod(() async {
      await _dao.clearSentEvents();
    }, AnalyticsInboxException.new, 'clearSentEvents');
  }

  /// Clear all events
  Future<void> clearAllEvents() {
    return tryMethod(() async {
      await _dao.clearAllEvents();
    }, AnalyticsInboxException.new, 'clearAllEvents');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Get unsent events for batch sending
  Future<List<AnalyticsInboxEntryData>> getUnsentEvents({int? limit}) {
    return tryMethod(() async {
      return _dao.getUnsentEvents(limit: limit);
    }, AnalyticsInboxException.new, 'getUnsentEvents');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch grouped unsent events (for inbox UI)
  Stream<List<AnalyticsInboxGroupedEntry>> watchGroupedUnsent() {
    return _dao.watchGroupedUnsent();
  }

  /// Watch total unsent count (for badge display)
  Stream<int> watchUnsentCount() {
    return _dao.watchUnsentCount();
  }
}
