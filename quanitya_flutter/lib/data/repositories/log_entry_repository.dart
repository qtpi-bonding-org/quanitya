import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../logic/templates/enums/field_enum.dart';
import '../dao/log_entry_dual_dao.dart';
import '../dao/log_entry_query_dao.dart';
import '../dao/template_query_dao.dart';
import '../db/app_database.dart';
import '../../logic/templates/models/shared/field_validator.dart';
import '../../logic/templates/services/shared/field_validators.dart';
import '../../logic/log_entries/models/log_entry.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/tracker_template.dart';
import '../interfaces/log_entry_interface.dart';

/// Exception thrown when log entry validation fails
class LogEntryValidationException implements Exception {
  final List<String> errors;
  LogEntryValidationException(this.errors);

  @override
  String toString() => 'LogEntryValidationException: ${errors.join(', ')}';
}

/// Exception thrown when referenced template is not found
class TemplateNotFoundException implements Exception {
  final String templateId;
  TemplateNotFoundException(this.templateId);

  @override
  String toString() =>
      'TemplateNotFoundException: Template $templateId not found';
}

/// Implementation of ILogEntryRepository.
///
/// Uses LogEntryDualDao for writes (E2EE) and LogEntryQueryDao for reads.
/// Validates log entry data against template schema before persisting.
@Injectable(as: ILogEntryRepository)
class LogEntryRepository implements ILogEntryRepository {
  final LogEntryDualDao _writeDao;
  final LogEntryQueryDao _queryDao;
  final TemplateQueryDao _templateQueryDao;
  final AppDatabase _db;

  LogEntryRepository(
    this._writeDao,
    this._queryDao,
    this._templateQueryDao,
    this._db,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Watch Methods (Streams)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<LogEntryModel>> watchEntriesForTemplate(String templateId) {
    return _queryDao.watchByTemplateId(templateId);
  }

  @override
  Stream<List<LogEntryModel>> watchAllEntries() {
    return _queryDao.watchAll();
  }

  @override
  Stream<List<LogEntryModel>> watchEntriesInDateRange(
    String templateId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..where((t) => t.occurredAt.isBiggerOrEqualValue(startDate))
      ..where((t) => t.occurredAt.isSmallerOrEqualValue(endDate))
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map(_writeDao.entityToModel).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Temporal Streams (Past / Future)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<LogEntryModel>> watchPastEntries({String? templateId}) {
    return _queryDao.watchLogged(templateId: templateId);
  }

  @override
  Stream<List<LogEntryModel>> watchUpcomingEntries({String? templateId}) {
    return _queryDao.watchTodos(templateId: templateId);
  }

  @override
  Stream<List<LogEntryModel>> watchMissedEntries({String? templateId}) {
    return _queryDao.watchMissed(templateId: templateId);
  }

  @override
  Stream<List<LogEntryWithContext>> watchPastEntriesWithContext({
    String? templateId,
    bool sortAscending = false,
  }) {
    return _queryDao.watchLoggedWithContext(
      templateId: templateId,
      sortOrder: sortAscending ? OrderingMode.asc : OrderingMode.desc,
    );
  }

  @override
  Stream<List<LogEntryWithContext>> watchUpcomingEntriesWithContext({
    String? templateId,
    bool sortAscending = true,
  }) {
    return _queryDao.watchTodosWithContext(
      templateId: templateId,
      sortOrder: sortAscending ? OrderingMode.asc : OrderingMode.desc,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Temporal Reads (Past / Future)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<LogEntryModel>> getPastEntries({String? templateId}) async {
    return _queryDao.findLogged(templateId: templateId);
  }

  @override
  Future<List<LogEntryModel>> getUpcomingEntries({String? templateId}) async {
    return _queryDao.findTodos(templateId: templateId);
  }

  @override
  Future<List<LogEntryModel>> getMissedEntries({String? templateId}) async {
    return _queryDao.findMissed(templateId: templateId);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Read Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<LogEntryModel?> getEntry(String id) async {
    return _queryDao.findById(id);
  }

  @override
  Future<List<LogEntryModel>> getRecentEntries(
    String templateId,
    int limit,
  ) async {
    return _queryDao.findRecentEntries(templateId, limit);
  }

  @override
  Future<List<LogEntryModel>> getEntriesForTemplate(String templateId) async {
    return _queryDao.findByTemplateId(templateId);
  }

  @override
  Future<List<LogEntryModel>> getAllEntries() async {
    return _queryDao.findAll();
  }

  @override
  Future<int> countEntriesForTemplate(String templateId) async {
    return _queryDao.countByTemplateId(templateId);
  }

  @override
  Future<int> countAllEntries() async {
    return _queryDao.countAll();
  }

  @override
  Future<List<TemplateSummary>> getTemplateSummaries() async {
    return _queryDao.getTemplateSummaries();
  }

  @override
  Stream<List<TemplateSummary>> watchTemplateSummaries() {
    return _queryDao.watchTemplateSummaries();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write Methods (with validation)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveLogEntry(LogEntryModel entry) async {
    // 1. Fetch and validate template exists
    final template = await _getTemplateOrThrow(entry.templateId);

    // 2. Validate entry data against template schema (skip for todos —
    //    they're placeholders with empty data, filled when logged)
    if (entry.occurredAt != null) {
      final errors = _validateDataAgainstTemplate(entry.data, template);
      if (errors.isNotEmpty) {
        throw LogEntryValidationException(errors);
      }
    }

    // 3. Save via dual DAO (handles E2EE)
    // FTS index is updated automatically via SQLite triggers
    final entity = _writeDao.modelToEntity(entry);
    await _writeDao.upsert(entity);
  }

  @override
  Future<void> updateLogEntry(LogEntryModel entry) async {
    // 1. Verify entry exists
    final existing = await _queryDao.findById(entry.id);
    if (existing == null) {
      throw StateError('LogEntry ${entry.id} not found');
    }

    // 2. Fetch and validate template
    final template = await _getTemplateOrThrow(entry.templateId);

    // 3. Validate entry data against template schema
    final errors = _validateDataAgainstTemplate(entry.data, template);
    if (errors.isNotEmpty) {
      throw LogEntryValidationException(errors);
    }

    // 4. Update via dual DAO (upsert handles both insert and update)
    // FTS index is updated automatically via SQLite triggers
    final entity = _writeDao.modelToEntity(entry);
    await _writeDao.upsert(entity);
  }

  @override
  Future<void> deleteLogEntry(String id) async {
    // FTS index is updated automatically via SQLite triggers
    await _writeDao.delete(id);
  }

  @override
  Future<int> deleteAllEntriesForTemplate(String templateId) async {
    final entries = await _queryDao.findByTemplateId(templateId);
    for (final entry in entries) {
      await _writeDao.delete(entry.id);
    }
    return entries.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sync Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<int> syncFromEncryptedStorage({String? templateId}) async {
    // Handled by E2EE Puller - this is a no-op placeholder
    return 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<String>> validateEntryData(LogEntryModel entry) async {
    final template = await _getTemplateOrThrow(entry.templateId);
    return _validateDataAgainstTemplate(entry.data, template);
  }

  /// Validates that entry data matches the template's field schema.
  ///
  /// Checks:
  /// - All required fields are present
  /// - Field types match expected types
  /// - Values pass field validators (min/max, etc.)
  List<String> _validateDataAgainstTemplate(
    Map<String, dynamic> data,
    TrackerTemplateModel template,
  ) {
    final errors = <String>[];

    for (final field in template.fields) {
      if (field.isDeleted) continue; // Skip deleted fields

      final value = data[field.id];

      // Check required fields (all fields required by default unless optional validator)
      final isOptional = field.validators.any(
        (v) => v.validatorType == ValidatorType.optional,
      );
      if (!isOptional &&
          (value == null || (value is String && value.isEmpty))) {
        errors.add('${field.label} is required');
        continue;
      }

      // Skip type validation if value is null and field is optional
      if (value == null) continue;

      // Validate type matches
      final typeError = _validateFieldType(field, value);
      if (typeError != null) {
        errors.add(typeError);
        continue;
      }

      // Run field validators
      for (final validator in field.validators) {
        final validatorError = _runValidator(validator, value, field.label);
        if (validatorError != null) {
          errors.add(validatorError);
        }
      }
    }

    // Check for extra fields not in template
    final templateFieldIds = template.fields.map((f) => f.id).toSet();
    for (final key in data.keys) {
      if (!templateFieldIds.contains(key)) {
        errors.add('Unknown field: $key');
      }
    }

    return errors;
  }

  /// Validates that a value matches the expected field type.
  /// For isList fields, validates the value is a List and checks each item.
  String? _validateFieldType(TemplateField field, dynamic value) {
    if (field.isList) {
      if (value is! List) return '${field.label} must be a list';
      for (int i = 0; i < value.length; i++) {
        final itemError = _validateScalarType(field, value[i]);
        if (itemError != null) return '$itemError (item ${i + 1})';
      }
      return null;
    }
    return _validateScalarType(field, value);
  }

  /// Validates a single scalar value against the field's expected type.
  String? _validateScalarType(TemplateField field, dynamic value) {
    final label = field.label;
    return switch (field.type) {
      FieldEnum.integer => value is int ? null : '$label must be an integer',
      FieldEnum.float => value is num ? null : '$label must be a number',
      FieldEnum.boolean => value is bool ? null : '$label must be a boolean',
      FieldEnum.text => value is String ? null : '$label must be text',
      FieldEnum.datetime => _validateDateTime(value, label),
      FieldEnum.enumerated => _validateEnumerated(value, field.options, label),
      FieldEnum.dimension => value is num ? null : '$label must be a number',
      FieldEnum.reference =>
        value is String ? null : '$label must be a reference ID',
      FieldEnum.location => _validateLocation(value, label),
    };
  }

  String? _validateLocation(dynamic value, String label) {
    if (value is! Map) return '$label must be a location';
    if (value['latitude'] is! num || value['longitude'] is! num) {
      return '$label must have numeric latitude and longitude';
    }
    return null;
  }

  String? _validateDateTime(dynamic value, String label) {
    if (value is DateTime) return null;
    if (value is String) {
      try {
        DateTime.parse(value);
        return null;
      } catch (_) {
        return '$label must be a valid date/time';
      }
    }
    return '$label must be a date/time';
  }

  String? _validateEnumerated(
    dynamic value,
    List<String>? options,
    String label,
  ) {
    if (value is! String) return '$label must be a string';
    if (options == null || options.isEmpty) return null;
    if (!options.contains(value)) {
      return '$label must be one of: ${options.join(', ')}';
    }
    return null;
  }

  /// Runs field validators using centralized FieldValidators.
  String? _runValidator(FieldValidator validator, dynamic value, String label) {
    // Use centralized validator for consistent behavior
    final validatorFn = FieldValidators.fromFieldValidators([validator], label);
    return validatorFn(value);
  }

  // Type validation helpers (not covered by FieldValidators)

  // ─────────────────────────────────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getEntryStatistics(String templateId) async {
    final entries = await _queryDao.findByTemplateId(templateId);

    if (entries.isEmpty) {
      return {
        'count': 0,
        'firstEntry': null,
        'lastEntry': null,
      };
    }

    final timestamps = entries.map((e) => e.displayTimestamp).toList()..sort();

    return {
      'count': entries.length,
      'firstEntry': timestamps.first.toIso8601String(),
      'lastEntry': timestamps.last.toIso8601String(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<TrackerTemplateModel> _getTemplateOrThrow(String templateId) async {
    final template = await _templateQueryDao.findById(templateId);
    if (template == null) {
      throw TemplateNotFoundException(templateId);
    }
    return template;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ingestion Support Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Set<String>> getDedupKeysForTemplate(String templateId) async {
    final entries = await _queryDao.findByTemplateId(templateId);
    final dedupKeys = <String>{};
    
    for (final entry in entries) {
      final dedupKey = entry.data['_dedupKey'];
      if (dedupKey != null && dedupKey is String && dedupKey.isNotEmpty) {
        dedupKeys.add(dedupKey);
      }
    }
    
    return dedupKeys;
  }

  @override
  Future<void> bulkInsert(List<LogEntryModel> entries) async {
    if (entries.isEmpty) return;
    
    // Convert models to entities
    final entities = entries.map(_writeDao.modelToEntity).toList();
    
    // Use DualDao.bulkUpsert for efficient batch writes
    // Skips validation - imported data already validated by adapter
    await _writeDao.bulkUpsert(entities);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Analytics Support Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<({DateTime date, num value})>> getTimeSeriesForField(String fieldId) async {
    final entries = await _queryDao.findAll();
    final timeSeriesPoints = <({DateTime date, num value})>[];
    
    for (final entry in entries) {
      final fieldValue = entry.data[fieldId];
      if (fieldValue != null && fieldValue is num) {
        timeSeriesPoints.add((
          date: entry.displayTimestamp,
          value: fieldValue,
        ));
      }
    }
    
    // Sort by date ascending for analytics processing
    timeSeriesPoints.sort((a, b) => a.date.compareTo(b.date));
    return timeSeriesPoints;
  }
}
