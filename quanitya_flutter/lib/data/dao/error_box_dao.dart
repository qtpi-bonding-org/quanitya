import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// DAO for error box operations.
///
/// Handles storage and retrieval of privacy-preserving error reports.
/// Uses fingerprinting for automatic deduplication.
@lazySingleton
class ErrorBoxDao {
  final AppDatabase _db;

  ErrorBoxDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Save an error entry with automatic deduplication
  Future<void> saveError(ErrorEntry error) async {
    final fingerprint = _generateFingerprint(error);
    final now = DateTime.now();
    
    // Check if error with same fingerprint already exists
    final existing = await (_db.select(_db.errorBoxEntries)
          ..where((e) => e.fingerprint.equals(fingerprint)))
        .getSingleOrNull();
    
    if (existing != null) {
      // Increment occurrence count and update last occurred time
      await (_db.update(_db.errorBoxEntries)
            ..where((e) => e.fingerprint.equals(fingerprint)))
          .write(ErrorBoxEntriesCompanion(
        occurrenceCount: Value(existing.occurrenceCount + 1),
        timestamp: Value(now), // Update to latest occurrence time
      ));
    } else {
      // Insert new error with generated UUID
      const uuid = Uuid();
      await _db.into(_db.errorBoxEntries).insert(
        ErrorBoxEntriesCompanion.insert(
          id: uuid.v4(),
          errorType: error.errorType,
          errorCode: error.errorCode,
          source: error.source,
          stackTrace: error.stackTrace,
          userMessage: Value(error.userMessage),
          timestamp: error.timestamp,
          fingerprint: fingerprint,
        ),
      );
    }
  }

  /// Mark an error as sent
  Future<void> markAsSent(String id) async {
    await (_db.update(_db.errorBoxEntries)
          ..where((e) => e.id.equals(id)))
        .write(const ErrorBoxEntriesCompanion(
      isSent: Value(true),
    ));
  }

  /// Delete an error by ID
  Future<void> deleteError(String id) async {
    await (_db.delete(_db.errorBoxEntries)
          ..where((e) => e.id.equals(id)))
        .go();
  }

  /// Clear all sent errors
  Future<void> clearSentErrors() async {
    await (_db.delete(_db.errorBoxEntries)
          ..where((e) => e.isSent.equals(true)))
        .go();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a single error by ID
  Future<ErrorBoxEntry?> getErrorById(String id) async {
    final entry = await (_db.select(_db.errorBoxEntries)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    
    return entry != null ? _toErrorBoxEntry(entry) : null;
  }

  /// Get all unsent errors
  Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    final entries = await (_db.select(_db.errorBoxEntries)
          ..where((e) => e.isSent.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
        .get();
    
    return entries.map(_toErrorBoxEntry).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch all unsent errors (reactive)
  Stream<List<ErrorBoxEntry>> watchUnsentErrors() {
    final query = _db.select(_db.errorBoxEntries)
      ..where((e) => e.isSent.equals(false))
      ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]);
    
    return query.watch().map((rows) => rows.map(_toErrorBoxEntry).toList());
  }

  /// Watch count of unsent errors
  Stream<int> watchUnsentCount() {
    final query = _db.selectOnly(_db.errorBoxEntries)
      ..addColumns([_db.errorBoxEntries.id.count()])
      ..where(_db.errorBoxEntries.isSent.equals(false));
    
    return query.watchSingle().map((row) => row.read(_db.errorBoxEntries.id.count()) ?? 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Generate fingerprint for deduplication
  /// 
  /// Combines error type, source, and first line of stack trace
  /// to create a unique identifier for similar errors.
  String _generateFingerprint(ErrorEntry error) {
    final stackFirstLine = error.stackTrace.split('\n').first;
    return '${error.errorType}|${error.source}|$stackFirstLine';
  }

  /// Convert Drift data class to ErrorBoxEntry
  ErrorBoxEntry _toErrorBoxEntry(ErrorBoxEntryData data) {
    return ErrorBoxEntry(
      id: data.id,
      fingerprint: data.fingerprint,
      errorData: ErrorEntry(
        source: data.source,
        errorType: data.errorType,
        errorCode: data.errorCode,
        stackTrace: data.stackTrace,
        userMessage: data.userMessage,
        timestamp: data.timestamp,
      ),
      occurrenceCount: data.occurrenceCount,
      firstOccurred: data.timestamp,
      lastOccurred: data.timestamp,
      wasSent: data.isSent,
    );
  }
}
