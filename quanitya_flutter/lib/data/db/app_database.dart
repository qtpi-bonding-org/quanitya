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
      },
    );
  }
}
