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
  
  /// AnalysisScript table pairing
  /// Links analysis_scripts ↔ encrypted_analysis_scripts
  static TablePair<AnalysisScript, EncryptedAnalysisScript> analysisScript(AppDatabase db) =>
    TablePair<AnalysisScript, EncryptedAnalysisScript>(
      localTable: db.analysisScripts,
      encryptedTable: db.encryptedAnalysisScripts,
      encryptedTableName: 'encrypted_analysis_scripts',
    );
  
  /// TemplateAesthetics table pairing
  /// Links template_aesthetics ↔ encrypted_template_aesthetics
  static TablePair<TemplateAesthetic, EncryptedTemplateAesthetic> templateAesthetics(AppDatabase db) =>
    TablePair<TemplateAesthetic, EncryptedTemplateAesthetic>(
      localTable: db.templateAesthetics,
      encryptedTable: db.encryptedTemplateAesthetics,
      encryptedTableName: 'encrypted_template_aesthetics',
    );

  // Private constructor to prevent instantiation
  TablePairs._();
}