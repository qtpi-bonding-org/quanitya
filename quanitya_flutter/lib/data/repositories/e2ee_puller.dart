import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../dao/dual_dao.dart';
import '../dao/table_pairs.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../logic/analytics/models/analysis_enums.dart';

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
    debugPrint(
      'E2EEPuller: Decrypting record ${(encrypted as dynamic).id} (length: ${encryptedDataString.length})',
    );
    final encryptedBytes = base64.decode(encryptedDataString);
    final decryptedJson = await encryption.decryptData(encryptedBytes);
    final entityData = jsonDecode(decryptedJson) as Map<String, dynamic>;
    debugPrint(
      'E2EEPuller: Successfully decrypted record ${(encrypted as dynamic).id}',
    );

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
    debugPrint(
      'E2EEPuller: Upserting decrypted ${tables.localTable.aliasedName} record $entityId',
    );
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

/// AnalysisPipeline processor - type-safe pairing
class AnalysisPipelineProcessor
    extends
        EncryptedTableProcessor<AnalysisPipeline, EncryptedAnalysisPipeline> {
  AnalysisPipelineProcessor({required super.db, required super.encryption})
    : super(tables: TablePairs.analysisPipeline(db));

  @override
  AnalysisPipeline jsonToEntity(Map<String, dynamic> json) {
    // Convert decrypted JSON to Drift Entity (Script-Based)
    return AnalysisPipeline(
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
  Insertable<AnalysisPipeline> entityToInsertable(AnalysisPipeline entity) {
    return AnalysisPipelinesCompanion(
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
  String getEntityId(AnalysisPipeline entity) => entity.id;

  @override
  DateTime getEntityUpdatedAt(AnalysisPipeline entity) => entity.updatedAt;

  @override
  Future<AnalysisPipeline?> findLocalById(String id) async {
    return await (db.select(
      db.analysisPipelines,
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
  late final AnalysisPipelineProcessor _pipelineProcessor;

  StreamSubscription<List<EncryptedTemplate>>? _templateSubscription;
  StreamSubscription<List<EncryptedEntry>>? _entrySubscription;
  StreamSubscription<List<EncryptedSchedule>>? _scheduleSubscription;
  StreamSubscription<List<EncryptedAnalysisPipeline>>? _pipelineSubscription;
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
    _pipelineProcessor = AnalysisPipelineProcessor(
      db: _db,
      encryption: _encryption,
    );
  }

  @override
  Future<void> initialize() async {
    if (_isListening) return;

    debugPrint('E2EEPuller: Initializing streams...');

    // Start listening to encrypted table changes from PowerSync
    // Each processor handles its own table pair safely
    _templateSubscription = _db.select(_db.encryptedTemplates).watch().listen((
      templates,
    ) async {
      debugPrint(
        'E2EEPuller: Received ${templates.length} encrypted templates',
      );
      await _templateProcessor.processEncryptedRecords(templates);
      _lastSyncTime = DateTime.now();
    });

    _entrySubscription = _db.select(_db.encryptedEntries).watch().listen((
      entries,
    ) async {
      debugPrint(
        'E2EEPuller: Received ${entries.length} encrypted entries in shadow table',
      );
      if (entries.isNotEmpty) {
        debugPrint(
          'E2EEPuller: Entry IDs: ${entries.map((e) => (e as dynamic).id).join(", ")}',
        );
      }
      await _entryProcessor.processEncryptedRecords(entries);
      _lastSyncTime = DateTime.now();
    });

    _scheduleSubscription = _db.select(_db.encryptedSchedules).watch().listen((
      schedules,
    ) async {
      debugPrint(
        'E2EEPuller: Received ${schedules.length} encrypted schedules',
      );
      await _scheduleProcessor.processEncryptedRecords(schedules);
      _lastSyncTime = DateTime.now();
    });

    _pipelineSubscription = _db
        .select(_db.encryptedAnalysisPipelines)
        .watch()
        .listen((pipelines) async {
          debugPrint(
            'E2EEPuller: Received ${pipelines.length} encrypted pipelines',
          );
          await _pipelineProcessor.processEncryptedRecords(pipelines);
          _lastSyncTime = DateTime.now();
        });

    _isListening = true;
    _lastSyncTime = DateTime.now();
    debugPrint('E2EEPuller: Streams initialized and listening');
  }

  @override
  Future<void> dispose() async {
    await _templateSubscription?.cancel();
    await _entrySubscription?.cancel();
    await _scheduleSubscription?.cancel();
    await _pipelineSubscription?.cancel();
    _templateSubscription = null;
    _entrySubscription = null;
    _scheduleSubscription = null;
    _pipelineSubscription = null;
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
        .select(_db.encryptedAnalysisPipelines)
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
