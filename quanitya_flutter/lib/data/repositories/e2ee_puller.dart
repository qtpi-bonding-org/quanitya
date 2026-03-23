import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../dao/dual_dao.dart';
import '../dao/table_pairs.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import '../../logic/analysis/enums/analysis_output_mode.dart';
import '../../logic/analysis/models/analysis_enums.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';

/// Interface for background decryption and sync hydration
///
/// The E2EE Puller listens to PowerSync changes in encrypted shadow tables
/// and decrypts them to local plaintext tables for fast access.
///
/// Uses Drift streams to automatically detect PowerSync updates via
/// SqliteAsyncDriftConnection integration.
abstract class IE2EEPuller {
  /// Initialize and start listening to encrypted table changes
  Future<void> initialize();

  /// Stop listening and cleanup resources
  Future<void> dispose();

  /// Check if the puller is currently active
  bool get isListening;

  /// Get the current sync status
  Future<SyncStatus> getSyncStatus();
}

/// Type-safe processor for encrypted table changes
///
/// Handles decryption from encrypted tables to local tables
/// using the same TablePair pattern as Dual DAO for type safety.
///
/// Echo Prevention:
/// Before upserting, compares the decrypted entity's updatedAt with the
/// existing local record's updatedAt. Skips write if local is same or newer.
/// This prevents redundant writes when DualDAO triggers the Puller via
/// its write to the encrypted table.
abstract class EncryptedTableProcessor<
  TLocal extends DataClass,
  TEncrypted extends DataClass
> {
  final AppDatabase db;
  final IDataEncryptionService encryption;
  final TablePair<TLocal, TEncrypted> tables;

  EncryptedTableProcessor({
    required this.db,
    required this.encryption,
    required this.tables,
  });

  /// Convert decrypted JSON to local entity
  TLocal jsonToEntity(Map<String, dynamic> json);

  /// Convert entity to insertable for database operations
  Insertable<TLocal> entityToInsertable(TLocal entity);

  /// Get the entity's ID for lookup
  String getEntityId(TLocal entity);

  /// Get the entity's updatedAt timestamp for comparison
  DateTime getEntityUpdatedAt(TLocal entity);

  /// Find existing local record by ID (for timestamp comparison)
  Future<TLocal?> findLocalById(String id);

  /// Process encrypted records and decrypt to local table
  Future<void> processEncryptedRecords(
    List<TEncrypted> encryptedRecords,
  ) async {
    for (final encrypted in encryptedRecords) {
      try {
        await _processEncryptedRecord(encrypted);
      } catch (e) {
        // Log error but continue processing other records
        debugPrint(
          'E2EEPuller: Error processing encrypted record '
          '${(encrypted as dynamic).id}: $e',
        );
      }
    }
  }

  /// Decrypt single record and upsert to local table
  ///
  /// Echo Prevention: Skips write if local record has same or newer updatedAt.
  /// This prevents redundant writes when the Puller is triggered by DualDAO's
  /// write to the encrypted table (which happens in the same transaction as
  /// the local table write).
  Future<void> _processEncryptedRecord(TEncrypted encrypted) async {
    // Decrypt the data - decode base64 first, then decrypt
    final encryptedDataString = (encrypted as dynamic).encryptedData as String;
    final encryptedBytes = base64.decode(encryptedDataString);
    final decryptedJson = await encryption.decryptData(encryptedBytes);
    final entityData = jsonDecode(decryptedJson) as Map<String, dynamic>;

    // Convert to local entity
    final localEntity = jsonToEntity(entityData);
    final entityId = getEntityId(localEntity);
    final incomingUpdatedAt = getEntityUpdatedAt(localEntity);

    // Echo Prevention: Check if local record is same or newer
    final existingLocal = await findLocalById(entityId);
    if (existingLocal != null) {
      final existingUpdatedAt = getEntityUpdatedAt(existingLocal);
      if (!existingUpdatedAt.isBefore(incomingUpdatedAt)) {
        // Local is same or newer - skip redundant write
        return;
      }
    }

    // Upsert to local table (insert or update)
    await db
        .into(tables.localTable)
        .insertOnConflictUpdate(entityToInsertable(localEntity));
  }
}

/// TrackerTemplate processor - type-safe pairing
class TrackerTemplateProcessor
    extends EncryptedTableProcessor<TrackerTemplate, EncryptedTemplate> {
  TrackerTemplateProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.trackerTemplate(db));

  @override
  TrackerTemplate jsonToEntity(Map<String, dynamic> json) {
    // JSON comes from TrackerTemplateModel.toJson() which has 'fields' as List
    // We need to convert to Drift entity which has 'fieldsJson' as String
    final fields = json['fields'];
    final fieldsJson = fields != null ? jsonEncode(fields) : '[]';

    return TrackerTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      fieldsJson: fieldsJson,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  @override
  Insertable<TrackerTemplate> entityToInsertable(TrackerTemplate entity) {
    return TrackerTemplatesCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      fieldsJson: Value(entity.fieldsJson),
      updatedAt: Value(entity.updatedAt),
      isArchived: Value(entity.isArchived),
    );
  }

  @override
  String getEntityId(TrackerTemplate entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(TrackerTemplate entity) => entity.updatedAt;

  @override
  Future<TrackerTemplate?> findLocalById(String id) async {
    return await (db.select(
      db.trackerTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// LogEntry processor - type-safe pairing
class LogEntryProcessor
    extends EncryptedTableProcessor<LogEntry, EncryptedEntry> {
  LogEntryProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.logEntry(db));

  @override
  LogEntry jsonToEntity(Map<String, dynamic> json) {
    // JSON comes from LogEntryModel.toJson() which has 'data' as Map
    // We need to convert to Drift entity which has 'dataJson' as String
    final data = json['data'];
    final dataJson = data != null ? jsonEncode(data) : '{}';

    return LogEntry(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : null,
      dataJson: dataJson,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Insertable<LogEntry> entityToInsertable(LogEntry entity) {
    return LogEntriesCompanion(
      id: Value(entity.id),
      templateId: Value(entity.templateId),
      scheduledFor: Value(entity.scheduledFor),
      occurredAt: Value(entity.occurredAt),
      dataJson: Value(entity.dataJson),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  String getEntityId(LogEntry entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(LogEntry entity) => entity.updatedAt;

  @override
  Future<LogEntry?> findLocalById(String id) async {
    return await (db.select(
      db.logEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// Schedule processor - type-safe pairing
class ScheduleProcessor
    extends EncryptedTableProcessor<Schedule, EncryptedSchedule> {
  ScheduleProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.schedule(db));

  @override
  Schedule jsonToEntity(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      recurrenceRule: json['recurrenceRule'] as String,
      reminderOffsetMinutes: json['reminderOffsetMinutes'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      lastGeneratedAt: json['lastGeneratedAt'] != null
          ? DateTime.parse(json['lastGeneratedAt'] as String)
          : null,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Insertable<Schedule> entityToInsertable(Schedule entity) {
    return SchedulesCompanion(
      id: Value(entity.id),
      templateId: Value(entity.templateId),
      recurrenceRule: Value(entity.recurrenceRule),
      reminderOffsetMinutes: Value(entity.reminderOffsetMinutes),
      isActive: Value(entity.isActive),
      lastGeneratedAt: Value(entity.lastGeneratedAt),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  String getEntityId(Schedule entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(Schedule entity) => entity.updatedAt;

  @override
  Future<Schedule?> findLocalById(String id) async {
    return await (db.select(
      db.schedules,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// AnalysisScript processor - type-safe pairing
class AnalysisScriptProcessor
    extends
        EncryptedTableProcessor<AnalysisScript, EncryptedAnalysisScript> {
  AnalysisScriptProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.analysisScript(db));

  @override
  AnalysisScript jsonToEntity(Map<String, dynamic> json) {
    // Convert decrypted JSON to Drift Entity (Script-Based)
    return AnalysisScript(
      id: json['id'] as String,
      name: json['name'] as String,
      fieldId: json['fieldId'] as String,
      outputMode: AnalysisOutputMode.values.byName(json['outputMode'] as String),
      snippetLanguage: AnalysisSnippetLanguage.values.byName(json['snippetLanguage'] as String),
      snippet: json['snippet'] as String,
      reasoning: json['reasoning'] as String?,
      metadataJson: json['metadataJson'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Insertable<AnalysisScript> entityToInsertable(AnalysisScript entity) {
    return AnalysisScriptsCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      fieldId: Value(entity.fieldId),
      outputMode: Value(entity.outputMode),
      snippetLanguage: Value(entity.snippetLanguage),
      snippet: Value(entity.snippet),
      reasoning: Value(entity.reasoning),
      metadataJson: Value(entity.metadataJson),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  String getEntityId(AnalysisScript entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(AnalysisScript entity) => entity.updatedAt;

  @override
  Future<AnalysisScript?> findLocalById(String id) async {
    return await (db.select(
      db.analysisScripts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// TemplateAesthetics processor - type-safe pairing
class AestheticsProcessor
    extends EncryptedTableProcessor<TemplateAesthetic, EncryptedTemplateAesthetic> {
  AestheticsProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.templateAesthetics(db));

  @override
  TemplateAesthetic jsonToEntity(Map<String, dynamic> json) {
    final model = TemplateAestheticsModel.fromJson(json);
    return TemplateAesthetic(
      id: model.id,
      templateId: model.templateId,
      themeName: model.themeName,
      icon: model.icon,
      emoji: model.emoji,
      paletteJson: model.paletteJson,
      fontConfigJson: model.fontConfigJson,
      colorMappingsJson: model.colorMappingsJson,
      containerStyle: model.containerStyle?.name,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Insertable<TemplateAesthetic> entityToInsertable(TemplateAesthetic entity) {
    return TemplateAestheticsCompanion(
      id: Value(entity.id),
      templateId: Value(entity.templateId),
      themeName: Value(entity.themeName),
      icon: Value(entity.icon),
      emoji: Value(entity.emoji),
      paletteJson: Value(entity.paletteJson),
      fontConfigJson: Value(entity.fontConfigJson),
      colorMappingsJson: Value(entity.colorMappingsJson),
      containerStyle: Value(entity.containerStyle),
      updatedAt: Value(entity.updatedAt),
    );
  }

  @override
  String getEntityId(TemplateAesthetic entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(TemplateAesthetic entity) => entity.updatedAt;

  @override
  Future<TemplateAesthetic?> findLocalById(String id) async {
    return await (db.select(
      db.templateAesthetics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// Sync status information for monitoring E2EE operations
class SyncStatus {
  final DateTime lastSyncTime;
  final int pendingTemplates;
  final int pendingEntries;
  final int pendingSchedules;
  final int pendingPipelines;
  final bool isActive;
  final String? lastError;

  const SyncStatus({
    required this.lastSyncTime,
    required this.pendingTemplates,
    required this.pendingEntries,
    required this.pendingSchedules,
    required this.pendingPipelines,
    required this.isActive,
    this.lastError,
  });
}

/// Type-safe, stream-based E2EE Puller implementation
///
/// Uses TablePair pattern for type safety and prevents table mix-ups.
/// Listens to PowerSync changes via Drift streams and delegates to
/// type-safe processors for decryption.
///
/// PowerSync → encrypted_tables → Drift streams → processors → local_tables
@LazySingleton(as: IE2EEPuller)
class E2EEPuller implements IE2EEPuller {
  final AppDatabase _db;
  final IDataEncryptionService _encryption;

  // Type-safe processors using TablePair pattern
  late final TrackerTemplateProcessor _templateProcessor;
  late final LogEntryProcessor _entryProcessor;
  late final ScheduleProcessor _scheduleProcessor;
  late final AnalysisScriptProcessor _pipelineProcessor;
  late final AestheticsProcessor _aestheticsProcessor;

  /// Active subscription references, keyed by table name.
  /// Used to cancel and recreate subscriptions when checkpoint advances.
  final Map<String, StreamSubscription> _subscriptions = {};
  bool _isListening = false;
  DateTime? _lastSyncTime;

  E2EEPuller(this._db, this._encryption) {
    // Initialize type-safe processors with correct table pairings
    _templateProcessor = TrackerTemplateProcessor(
      db: _db,
      encryption: _encryption,
    );
    _entryProcessor = LogEntryProcessor(db: _db, encryption: _encryption);
    _scheduleProcessor = ScheduleProcessor(db: _db, encryption: _encryption);
    _pipelineProcessor = AnalysisScriptProcessor(
      db: _db,
      encryption: _encryption,
    );
    _aestheticsProcessor = AestheticsProcessor(
      db: _db,
      encryption: _encryption,
    );
  }

  /// Get the checkpoint timestamp for a table (null = first run, process all)
  Future<DateTime?> _getCheckpoint(String tableName) async {
    final row = await (_db.select(_db.pullerCheckpoints)
          ..where((t) => t.encryptedTable.equals(tableName)))
        .getSingleOrNull();
    return row?.lastProcessedAt;
  }

  /// Update the checkpoint to the max updated_at in the processed batch
  Future<void> _updateCheckpoint(String tableName, DateTime lastProcessedAt) async {
    await _db.into(_db.pullerCheckpoints).insertOnConflictUpdate(
      PullerCheckpointsCompanion(
        encryptedTable: Value(tableName),
        lastProcessedAt: Value(lastProcessedAt),
      ),
    );
  }

  /// Reset all checkpoints, forcing a full re-process on next stream emission.
  /// Call this when PowerSync performs a full re-sync.
  Future<void> resetCheckpoints() async {
    await _db.delete(_db.pullerCheckpoints).go();
    debugPrint('E2EEPuller: All checkpoints reset');
  }

  /// Start watching an encrypted table with checkpoint filtering.
  ///
  /// On first run (no checkpoint), processes all records.
  /// On subsequent runs, only processes records with updated_at >= checkpoint.
  /// After processing, advances the checkpoint and resubscribes.
  /// Build a watch stream for an encrypted table, filtered by checkpoint.
  ///
  /// Each encrypted table has the same shape (id, encrypted_data, updated_at).
  /// We use typed Drift queries per table to avoid dynamic dispatch issues
  /// with extension methods.
  Stream<List<T>> _buildFilteredStream<T extends DataClass>(
    SimpleSelectStatement<Table, T> query,
    Expression<bool> Function(DateTime checkpoint) whereClause,
    DateTime? checkpoint,
  ) {
    if (checkpoint != null) {
      query.where((_) => whereClause(checkpoint));
    }
    return query.watch();
  }

  Future<void> _startWatching<T extends DataClass>({
    required String tableName,
    required SimpleSelectStatement<Table, T> Function() queryBuilder,
    required Expression<bool> Function(DateTime checkpoint) whereClause,
    required EncryptedTableProcessor processor,
  }) async {
    // Cancel any existing subscription for this table
    await _subscriptions[tableName]?.cancel();

    final checkpoint = await _getCheckpoint(tableName);

    final stream = _buildFilteredStream(queryBuilder(), whereClause, checkpoint);

    // Track the effective checkpoint locally to filter already-processed records
    // without resubscribing. Drift's watch() re-emits on any table write, so we
    // filter in the listener instead of rebuilding the query.
    DateTime effectiveCheckpoint = checkpoint ?? DateTime.fromMillisecondsSinceEpoch(0);

    _subscriptions[tableName] = stream.listen((records) async {
      // Filter out records at or below the current checkpoint — Drift may
      // re-emit them after unrelated writes to the same table.
      final newRecords = records.where((record) {
        final updatedAt = (record as dynamic).updatedAt as DateTime;
        return updatedAt.isAfter(effectiveCheckpoint);
      }).toList();

      if (newRecords.isEmpty) return;

      debugPrint('E2EEPuller: Processing ${newRecords.length} $tableName');
      await processor.processEncryptedRecords(newRecords);

      // Advance checkpoint
      for (final record in newRecords) {
        final updatedAt = (record as dynamic).updatedAt as DateTime;
        if (updatedAt.isAfter(effectiveCheckpoint)) {
          effectiveCheckpoint = updatedAt;
        }
      }

      await _updateCheckpoint(tableName, effectiveCheckpoint);
      _lastSyncTime = DateTime.now();
    });
  }

  @override
  Future<void> initialize() async {
    if (_isListening) return;
    debugPrint('E2EEPuller: Initializing streams with checkpoints...');

    await _startWatching(
      tableName: 'encrypted_templates',
      queryBuilder: () => _db.select(_db.encryptedTemplates),
      whereClause: (cp) => _db.encryptedTemplates.updatedAt.isBiggerThanValue(cp),
      processor: _templateProcessor,
    );

    await _startWatching(
      tableName: 'encrypted_entries',
      queryBuilder: () => _db.select(_db.encryptedEntries),
      whereClause: (cp) => _db.encryptedEntries.updatedAt.isBiggerThanValue(cp),
      processor: _entryProcessor,
    );

    await _startWatching(
      tableName: 'encrypted_schedules',
      queryBuilder: () => _db.select(_db.encryptedSchedules),
      whereClause: (cp) => _db.encryptedSchedules.updatedAt.isBiggerThanValue(cp),
      processor: _scheduleProcessor,
    );

    await _startWatching(
      tableName: 'encrypted_analysis_scripts',
      queryBuilder: () => _db.select(_db.encryptedAnalysisScripts),
      whereClause: (cp) => _db.encryptedAnalysisScripts.updatedAt.isBiggerThanValue(cp),
      processor: _pipelineProcessor,
    );

    await _startWatching(
      tableName: 'encrypted_template_aesthetics',
      queryBuilder: () => _db.select(_db.encryptedTemplateAesthetics),
      whereClause: (cp) => _db.encryptedTemplateAesthetics.updatedAt.isBiggerThanValue(cp),
      processor: _aestheticsProcessor,
    );

    _isListening = true;
    _lastSyncTime = DateTime.now();
    debugPrint('E2EEPuller: Streams initialized with checkpoint filtering');
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _isListening = false;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<SyncStatus> getSyncStatus() async {
    final templateCount = await _db
        .select(_db.encryptedTemplates)
        .get()
        .then((list) => list.length);
    final entryCount = await _db
        .select(_db.encryptedEntries)
        .get()
        .then((list) => list.length);
    final scheduleCount = await _db
        .select(_db.encryptedSchedules)
        .get()
        .then((list) => list.length);
    final pipelineCount = await _db
        .select(_db.encryptedAnalysisScripts)
        .get()
        .then((list) => list.length);

    return SyncStatus(
      lastSyncTime: _lastSyncTime ?? DateTime.now(),
      pendingTemplates: templateCount,
      pendingEntries: entryCount,
      pendingSchedules: scheduleCount,
      pendingPipelines: pipelineCount,
      isActive: _isListening,
    );
  }
}
