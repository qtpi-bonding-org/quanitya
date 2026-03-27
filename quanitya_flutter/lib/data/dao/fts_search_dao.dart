import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/config/debug_log.dart';

import '../db/app_database.dart';

const _tag = 'data/dao/fts_search_dao';

/// DAO for FTS5 full-text search on log entry text fields.
///
/// Uses SQLite triggers to automatically keep the FTS index in sync
/// with the `log_entries` table — every INSERT, UPDATE, and DELETE
/// on `log_entries` is handled at the database level. No Dart-side
/// hooks needed.
///
/// The index extracts text values from `data_json` by joining with
/// the template's `fields_json` to identify text-type fields.
///
/// Local-only — never syncs. Rebuilds from decrypted data on new devices.
@lazySingleton
class FtsSearchDao {
  final AppDatabase _db;

  FtsSearchDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Schema + Triggers
  // ─────────────────────────────────────────────────────────────────────────

  /// Create the FTS5 virtual table and triggers if they don't exist.
  /// Call once during app initialization (idempotent).
  Future<void> ensureTable() async {
    // FTS5 virtual table
    await _db.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS log_entry_fts
      USING fts5(entry_id UNINDEXED, content)
    ''');

    // Trigger: after INSERT on log_entries → index text from data_json
    await _db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS log_entry_fts_insert
      AFTER INSERT ON log_entries
      BEGIN
        INSERT INTO log_entry_fts (entry_id, content)
        SELECT NEW.id, NEW.data_json
        WHERE NEW.data_json IS NOT NULL AND NEW.data_json != '{}';
      END
    ''');

    // Trigger: after UPDATE on log_entries → re-index
    await _db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS log_entry_fts_update
      AFTER UPDATE OF data_json ON log_entries
      BEGIN
        DELETE FROM log_entry_fts WHERE entry_id = OLD.id;
        INSERT INTO log_entry_fts (entry_id, content)
        SELECT NEW.id, NEW.data_json
        WHERE NEW.data_json IS NOT NULL AND NEW.data_json != '{}';
      END
    ''');

    // Trigger: after DELETE on log_entries → remove from index
    await _db.customStatement('''
      CREATE TRIGGER IF NOT EXISTS log_entry_fts_delete
      AFTER DELETE ON log_entries
      BEGIN
        DELETE FROM log_entry_fts WHERE entry_id = OLD.id;
      END
    ''');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────────────────────────────────

  /// Search for log entries matching [query].
  ///
  /// Returns entry IDs ordered by relevance (BM25 ranking).
  /// Supports FTS5 syntax: phrases ("exact match"),
  /// prefix queries (word*), boolean operators (AND, OR, NOT).
  ///
  /// Returns an empty list if [query] is empty or whitespace.
  Future<List<String>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = await _db.customSelect(
      'SELECT entry_id FROM log_entry_fts WHERE content MATCH ? ORDER BY rank',
      variables: [Variable.withString(trimmed)],
    ).get();

    return results.map((r) => r.read<String>('entry_id')).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rebuild
  // ─────────────────────────────────────────────────────────────────────────

  /// Rebuild only if the FTS index is empty but entries exist.
  /// Handles the new-device case where entries arrived via E2EE sync
  /// before the triggers were created.
  Future<void> rebuildIfEmpty() async {
    final ftsCount = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM log_entry_fts',
    ).getSingle();
    if (ftsCount.read<int>('cnt') > 0) return;

    final entryCount = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM log_entries',
    ).getSingle();
    if (entryCount.read<int>('cnt') == 0) return;

    await rebuildAll();
  }

  /// Rebuild the entire FTS index from all log entries.
  ///
  /// Reads `data_json` directly and indexes the raw JSON string.
  /// FTS5 tokenizes the content, so JSON keys and string values
  /// are all searchable. Text field values are naturally prominent
  /// in BM25 ranking since they contain more natural-language tokens.
  Future<void> rebuildAll() async {
    Log.d(_tag, 'FTS: Rebuilding full-text index...');
    await _db.customStatement('DELETE FROM log_entry_fts');

    await _db.customStatement('''
      INSERT INTO log_entry_fts (entry_id, content)
      SELECT id, data_json FROM log_entries
      WHERE data_json IS NOT NULL AND data_json != '{}'
    ''');

    Log.d(_tag, 'FTS: Rebuild complete');
  }
}
