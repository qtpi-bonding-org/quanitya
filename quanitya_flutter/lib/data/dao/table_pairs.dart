import '../db/app_database.dart';
import 'dual_dao.dart';

/// Predefined table pairs for type safety
/// 
/// This class prevents wrong table combinations by providing
/// compile-time validated pairings of local and encrypted tables.
/// 
/// The encryptedTableName is the PowerSync view name for raw SQL operations.
class TablePairs {
  /// TrackerTemplate table pairing
  /// Links tracker_templates ↔ encrypted_templates
  static TablePair<TrackerTemplate, EncryptedTemplate> trackerTemplate(AppDatabase db) => 
    TablePair<TrackerTemplate, EncryptedTemplate>(
      localTable: db.trackerTemplates,
      encryptedTable: db.encryptedTemplates,
      encryptedTableName: 'encrypted_templates',
    );
  
  /// LogEntry table pairing  
  /// Links log_entries ↔ encrypted_entries
  static TablePair<LogEntry, EncryptedEntry> logEntry(AppDatabase db) =>
    TablePair<LogEntry, EncryptedEntry>(
      localTable: db.logEntries,
      encryptedTable: db.encryptedEntries,
      encryptedTableName: 'encrypted_entries',
    );
  
  /// Schedule table pairing
  /// Links schedules ↔ encrypted_schedules
  static TablePair<Schedule, EncryptedSchedule> schedule(AppDatabase db) =>
    TablePair<Schedule, EncryptedSchedule>(
      localTable: db.schedules,
      encryptedTable: db.encryptedSchedules,
      encryptedTableName: 'encrypted_schedules',
    );
  
  /// AnalysisPipeline table pairing
  /// Links analysis_pipelines ↔ encrypted_analysis_pipelines
  static TablePair<AnalysisPipeline, EncryptedAnalysisPipeline> analysisPipeline(AppDatabase db) =>
    TablePair<AnalysisPipeline, EncryptedAnalysisPipeline>(
      localTable: db.analysisPipelines,
      encryptedTable: db.encryptedAnalysisPipelines,
      encryptedTableName: 'encrypted_analysis_pipelines',
    );
  
  // Private constructor to prevent instantiation
  TablePairs._();
}