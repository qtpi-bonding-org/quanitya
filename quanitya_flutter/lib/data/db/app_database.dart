import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync_sqlcipher/powersync.dart' hide Table;

import '../tables/tables.dart';
import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../logic/analysis/enums/analysis_output_mode.dart';
import '../../logic/analysis/models/analysis_enums.dart';

part 'app_database.g.dart';

/// Central database class for the Quanitya Tracker App
///
/// Integrates Drift with PowerSync using SqliteAsyncDriftConnection:
/// - All tables (local + encrypted) in single database file
/// - PowerSync automatically detects changes via sqlite_async
/// - Drift provides ORM interface for app logic
/// - PowerSync handles sync to PostgreSQL backend
@DriftDatabase(
  tables: [
    TrackerTemplates,
    LogEntries,
    Schedules,
    TemplateAesthetics,
    AnalysisScripts,
    EncryptedTemplates,
    EncryptedEntries,
    EncryptedSchedules,
    EncryptedAnalysisScripts,
    EncryptedTemplateAesthetics,
    ApiKeys,
    Webhooks,
    AppOperatingSettings,
    ErrorBoxEntries,
    Notifications,
    AnalyticsInboxEntries,
    OpenRouterModels,
    LlmProviderConfigs,
    PullerCheckpoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Main constructor - connects Drift to PowerSync database
  AppDatabase(PowerSyncDatabase powerSyncDb)
    : super(SqliteAsyncDriftConnection(powerSyncDb));

  /// Constructor for testing with custom executor
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // FTS5 virtual table — local-only full-text search on log entry text fields
        await customStatement('''
          CREATE VIRTUAL TABLE IF NOT EXISTS log_entry_fts
          USING fts5(entry_id UNINDEXED, content)
        ''');
      },
    );
  }

  /// Watch encrypted entry count and total size.
  ///
  /// Drift re-queries whenever the [EncryptedEntries] table changes.
  Stream<({int count, int bytes})> watchEncryptedStorageUsage() {
    return customSelect(
      'SELECT '
      'COUNT(*) AS cnt, '
      'COALESCE(SUM(LENGTH(encrypted_data)), 0) AS total_bytes '
      'FROM encrypted_entries',
      readsFrom: {encryptedEntries},
    ).watchSingle().map((row) => (
      count: row.read<int>('cnt'),
      bytes: row.read<int>('total_bytes'),
    ));
  }
}
