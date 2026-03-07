import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';

/// DAO for analytics inbox operations.
///
/// Handles local storage of analytics events for user-controlled sending.
/// Events are individual rows with timestamps (not aggregated).
@lazySingleton
class AnalyticsInboxDao {
  final AppDatabase _db;

  AnalyticsInboxDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Insert a new analytics event
  Future<void> insertEvent({
    required String eventName,
    required DateTime clientTimestamp,
    String? platform,
    String? props,
  }) async {
    await _db.into(_db.analyticsInboxEntries).insert(
      AnalyticsInboxEntriesCompanion.insert(
        eventName: eventName,
        clientTimestamp: clientTimestamp,
        platform: Value(platform),
        props: Value(props),
      ),
    );
  }

  /// Mark events as sent by their IDs
  Future<void> markAsSent(List<int> ids) async {
    await (_db.update(_db.analyticsInboxEntries)
          ..where((e) => e.id.isIn(ids)))
        .write(const AnalyticsInboxEntriesCompanion(
      isSent: Value(true),
    ));
  }

  /// Delete all sent events
  Future<void> clearSentEvents() async {
    await (_db.delete(_db.analyticsInboxEntries)
          ..where((e) => e.isSent.equals(true)))
        .go();
  }

  /// Delete all events (sent and unsent)
  Future<void> clearAllEvents() async {
    await _db.delete(_db.analyticsInboxEntries).go();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Get unsent events, optionally limited for batching
  Future<List<AnalyticsInboxEntryData>> getUnsentEvents({int? limit}) async {
    final query = _db.select(_db.analyticsInboxEntries)
      ..where((e) => e.isSent.equals(false))
      ..orderBy([(e) => OrderingTerm.asc(e.clientTimestamp)]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.get();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch unsent events grouped by event name with counts and latest timestamp
  Stream<List<AnalyticsInboxGroupedEntry>> watchGroupedUnsent() {
    final eventName = _db.analyticsInboxEntries.eventName;
    final count = _db.analyticsInboxEntries.id.count();
    final latestTimestamp = _db.analyticsInboxEntries.clientTimestamp.max();
    final earliestTimestamp = _db.analyticsInboxEntries.clientTimestamp.min();

    final query = _db.selectOnly(_db.analyticsInboxEntries)
      ..addColumns([eventName, count, latestTimestamp, earliestTimestamp])
      ..where(_db.analyticsInboxEntries.isSent.equals(false))
      ..groupBy([eventName])
      ..orderBy([OrderingTerm.desc(count)]);

    return query.watch().map((rows) => rows.map((row) {
          return AnalyticsInboxGroupedEntry(
            eventName: row.read(eventName)!,
            count: row.read(count)!,
            latestTimestamp: row.read(latestTimestamp)!,
            earliestTimestamp: row.read(earliestTimestamp)!,
          );
        }).toList());
  }

  /// Watch total count of unsent events
  Stream<int> watchUnsentCount() {
    final count = _db.analyticsInboxEntries.id.count();
    final query = _db.selectOnly(_db.analyticsInboxEntries)
      ..addColumns([count])
      ..where(_db.analyticsInboxEntries.isSent.equals(false));

    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }
}

/// Grouped analytics event for UI display
class AnalyticsInboxGroupedEntry {
  final String eventName;
  final int count;
  final DateTime latestTimestamp;
  final DateTime earliestTimestamp;

  const AnalyticsInboxGroupedEntry({
    required this.eventName,
    required this.count,
    required this.latestTimestamp,
    required this.earliestTimestamp,
  });
}
