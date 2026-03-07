import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' hide Table;

import '../tables/tables.dart';
import '../../features/app_operating_mode/models/app_operating_mode.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';

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
    AnalysisPipelines,
    EncryptedTemplates,
    EncryptedEntries,
    EncryptedSchedules,
    EncryptedAnalysisPipelines,
    ApiKeys,
    Webhooks,
    AppOperatingSettings,
    ErrorBoxEntries,
    Notifications,
    AnalyticsInboxEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Main constructor - connects Drift to PowerSync database
  AppDatabase(PowerSyncDatabase powerSyncDb)
    : super(SqliteAsyncDriftConnection(powerSyncDb));

  /// Constructor for testing with custom executor
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add error_box_entries table for privacy-preserving error reporting
          await m.createTable(errorBoxEntries);
        }
        if (from < 3) {
          // Add notifications table for server-to-client notifications
          await m.createTable(notifications);
        }
        if (from < 4) {
          // Add analytics inbox table for local-first analytics
          await m.createTable(analyticsInboxEntries);
          // Add analytics_auto_send column to app_operating_settings
          await m.addColumn(appOperatingSettings, appOperatingSettings.analyticsAutoSend);
        }
      },
    );
  }
}
