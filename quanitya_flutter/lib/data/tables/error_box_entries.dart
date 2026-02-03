import 'package:drift/drift.dart';

/// Local-only table for storing privacy-preserving error reports
/// 
/// This table is NOT synced to the server - errors are stored locally
/// until the user explicitly chooses to send them via the Error Box UI.
@DataClassName('ErrorBoxEntryData')
class ErrorBoxEntries extends Table {
  /// Unique identifier for this error entry
  TextColumn get id => text()();
  
  /// Error type (e.g., 'NetworkException', 'ValidationException')
  TextColumn get errorType => text()();
  
  /// Mapped error code (e.g., 'NET_001', 'VAL_002')
  TextColumn get errorCode => text()();
  
  /// Source cubit name (e.g., 'TemplateListCubit')
  TextColumn get source => text()();
  
  /// Complete stack trace (PII-free)
  TextColumn get stackTrace => text()();
  
  /// User-friendly message (optional, from exception mapper)
  TextColumn get userMessage => text().nullable()();
  
  /// When this error first occurred
  DateTimeColumn get timestamp => dateTime()();
  
  /// Number of times this error has occurred (deduplication)
  IntColumn get occurrenceCount => integer().withDefault(const Constant(1))();
  
  /// Whether this error has been sent to the server
  BoolColumn get isSent => boolean().withDefault(const Constant(false))();
  
  /// Fingerprint for deduplication (hash of errorType + source + stackTrace)
  TextColumn get fingerprint => text()();
  
  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {fingerprint}, // Ensure unique fingerprints for deduplication
  ];
}
