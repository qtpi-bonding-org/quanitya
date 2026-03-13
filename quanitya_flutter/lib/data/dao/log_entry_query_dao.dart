import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/log_entries/models/log_entry.dart';
import '../../logic/templates/models/shared/tracker_template.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';
import '../../logic/schedules/models/schedule.dart';

/// Summary data for each template's log entries.
class TemplateSummary {
  final String templateId;
  final int entryCount;
  final DateTime? lastLoggedAt;

  const TemplateSummary({
    required this.templateId,
    required this.entryCount,
    this.lastLoggedAt,
  });
}

/// Combined log entry with its related template, aesthetics, and schedule.
///
/// Provides all data needed to display a log entry in the UI without
/// additional queries.
class LogEntryWithContext {
  final LogEntryModel entry;
  final TrackerTemplateModel template;
  final TemplateAestheticsModel? aesthetics;
  final ScheduleModel? schedule;

  const LogEntryWithContext({
    required this.entry,
    required this.template,
    this.aesthetics,
    this.schedule,
  });
}

/// Read-only DAO for log entry queries with joins.
///
/// Provides efficient queries that fetch log entries with their
/// related template, aesthetics, and schedule data in single operations.
///
/// For write operations, use LogEntryDualDao.
@lazySingleton
class LogEntryQueryDao {
  final AppDatabase _db;

  LogEntryQueryDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Single Entry Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a log entry by ID
  Future<LogEntryModel?> findById(String id) async {
    final entity = await (_db.select(
      _db.logEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get a log entry with its template, aesthetics, and schedule
  Future<LogEntryWithContext?> findByIdWithContext(String id) async {
    final entry = await findById(id);
    if (entry == null) return null;
    return _loadContext(entry);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all entries for a template
  Future<List<LogEntryModel>> findByTemplateId(String templateId) async {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get recent entries for a template
  Future<List<LogEntryModel>> findRecentEntries(
    String templateId,
    int limit,
  ) async {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get all entries
  Future<List<LogEntryModel>> findAll() async {
    final query = _db.select(_db.logEntries)
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get entries for a template in a date range
  Future<List<LogEntryModel>> findByTemplateIdInRange(
    String templateId,
    DateTime start,
    DateTime end,
  ) async {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..where(
        (t) =>
            coalesce([
              t.occurredAt,
              t.scheduledFor,
            ]).isBiggerOrEqualValue(start) &
            coalesce([t.occurredAt, t.scheduledFor]).isSmallerOrEqualValue(end),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get all entries in a date range
  Future<List<LogEntryModel>> findInRange(DateTime start, DateTime end) async {
    final query = _db.select(_db.logEntries)
      ..where(
        (t) =>
            coalesce([
              t.occurredAt,
              t.scheduledFor,
            ]).isBiggerOrEqualValue(start) &
            coalesce([t.occurredAt, t.scheduledFor]).isSmallerOrEqualValue(end),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Watch entries for a template in a date range
  Stream<List<LogEntryModel>> watchByTemplateIdInRange(
    String templateId,
    DateTime start,
    DateTime end,
  ) {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..where(
        (t) =>
            coalesce([
              t.occurredAt,
              t.scheduledFor,
            ]).isBiggerOrEqualValue(start) &
            coalesce([t.occurredAt, t.scheduledFor]).isSmallerOrEqualValue(end),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Temporal Queries (TODO / MISSED / LOGGED)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get upcoming/todo entries (scheduledFor > now, occurredAt is null)
  Future<List<LogEntryModel>> findTodos({String? templateId}) async {
    final now = DateTime.now();
    var query = _db.select(_db.logEntries)
      ..where(
        (t) => t.scheduledFor.isBiggerThanValue(now) & t.occurredAt.isNull(),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.scheduledFor, mode: OrderingMode.asc),
      ]);

    if (templateId != null) {
      query = query..where((t) => t.templateId.equals(templateId));
    }
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get missed/overdue entries (scheduledFor < now, occurredAt is null)
  Future<List<LogEntryModel>> findMissed({String? templateId}) async {
    final now = DateTime.now();
    var query = _db.select(_db.logEntries)
      ..where(
        (t) => t.scheduledFor.isSmallerThanValue(now) & t.occurredAt.isNull(),
      )
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.scheduledFor, mode: OrderingMode.desc),
      ]);

    if (templateId != null) {
      query = query..where((t) => t.templateId.equals(templateId));
    }
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get logged/completed entries (occurredAt is not null)
  Future<List<LogEntryModel>> findLogged({String? templateId}) async {
    var query = _db.select(_db.logEntries)
      ..where((t) => t.occurredAt.isNotNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);

    if (templateId != null) {
      query = query..where((t) => t.templateId.equals(templateId));
    }
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch all entries for a template
  Stream<List<LogEntryModel>> watchByTemplateId(String templateId) {
    final query = _db.select(_db.logEntries)
      ..where((t) => t.templateId.equals(templateId))
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch all entries
  Stream<List<LogEntryModel>> watchAll() {
    final query = _db.select(_db.logEntries)
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch upcoming/todo entries
  Stream<List<LogEntryModel>> watchTodos({
    String? templateId,
    OrderingMode sortOrder = OrderingMode.asc,
  }) {
    final now = DateTime.now();
    final query = _db.select(_db.logEntries).join([
      leftOuterJoin(
        _db.trackerTemplates,
        _db.trackerTemplates.id.equalsExp(_db.logEntries.templateId),
      ),
      leftOuterJoin(
        _db.templateAesthetics,
        _db.templateAesthetics.templateId.equalsExp(_db.logEntries.templateId),
      ),
    ]);

    query.where(
      _db.logEntries.scheduledFor.isBiggerThanValue(now) &
          _db.logEntries.occurredAt.isNull(),
    );

    if (templateId != null) {
      query.where(_db.logEntries.templateId.equals(templateId));
    }

    query.orderBy([
      OrderingTerm(expression: _db.logEntries.scheduledFor, mode: sortOrder),
    ]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _entityToModel(row.readTable(_db.logEntries)))
          .toList(),
    );
  }

  /// Watch missed/overdue entries
  Stream<List<LogEntryModel>> watchMissed({String? templateId}) {
    final now = DateTime.now();
    var query = _db.select(_db.logEntries)
      ..where(
        (t) => t.scheduledFor.isSmallerThanValue(now) & t.occurredAt.isNull(),
      )
      ..orderBy([
        (t) =>
            OrderingTerm(expression: t.scheduledFor, mode: OrderingMode.desc),
      ]);

    if (templateId != null) {
      query = query..where((t) => t.templateId.equals(templateId));
    }
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch logged/completed entries
  Stream<List<LogEntryModel>> watchLogged({
    String? templateId,
    OrderingMode sortOrder = OrderingMode.desc,
  }) {
    final query = _db.select(_db.logEntries).join([
      leftOuterJoin(
        _db.trackerTemplates,
        _db.trackerTemplates.id.equalsExp(_db.logEntries.templateId),
      ),
      leftOuterJoin(
        _db.templateAesthetics,
        _db.templateAesthetics.templateId.equalsExp(_db.logEntries.templateId),
      ),
    ]);

    query.where(_db.logEntries.occurredAt.isNotNull());

    if (templateId != null) {
      query.where(_db.logEntries.templateId.equals(templateId));
    }

    query.orderBy([
      OrderingTerm(expression: _db.logEntries.occurredAt, mode: sortOrder),
    ]);

    return query.watch().map(
      (rows) => rows
          .map((row) => _entityToModel(row.readTable(_db.logEntries)))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Context-Enriched Queries (with template + aesthetics + schedule)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get entries with full context for a template
  Future<List<LogEntryWithContext>> findByTemplateIdWithContext(
    String templateId,
  ) async {
    final entries = await findByTemplateId(templateId);
    return _loadContextForList(entries);
  }

  /// Get entries with full context for a template in a date range
  Future<List<LogEntryWithContext>> findByTemplateIdInRangeWithContext(
    String templateId,
    DateTime start,
    DateTime end,
  ) async {
    final entries = await findByTemplateIdInRange(templateId, start, end);
    return _loadContextForList(entries);
  }

  /// Watch entries with full context for a template
  Stream<List<LogEntryWithContext>> watchByTemplateIdWithContext(
    String templateId,
  ) {
    return watchByTemplateId(templateId).asyncMap(_loadContextForList);
  }

  /// Get todos with full context
  Future<List<LogEntryWithContext>> findTodosWithContext({
    String? templateId,
  }) async {
    final entries = await findTodos(templateId: templateId);
    return _loadContextForList(entries);
  }

  /// Watch todos with full context
  Stream<List<LogEntryWithContext>> watchTodosWithContext({
    String? templateId,
    OrderingMode sortOrder = OrderingMode.asc,
    bool includeHidden = false,
  }) {
    return watchTodos(templateId: templateId, sortOrder: sortOrder).asyncMap(
      (entries) => _loadContextForList(entries, includeHidden: includeHidden),
    );
  }

  /// Watch logged entries with full context
  Stream<List<LogEntryWithContext>> watchLoggedWithContext({
    String? templateId,
    OrderingMode sortOrder = OrderingMode.desc,
    bool includeHidden = false,
  }) {
    return watchLogged(templateId: templateId, sortOrder: sortOrder).asyncMap(
      (entries) => _loadContextForList(entries, includeHidden: includeHidden),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Aesthetic-based Queries (find entries by aesthetic/icon)
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all entries for templates with a specific aesthetic (by icon)
  Future<List<LogEntryWithContext>> findByAestheticIcon(String icon) async {
    // First find all templates with this icon
    final aestheticsQuery = _db.select(_db.templateAesthetics)
      ..where((t) => t.icon.equals(icon));
    final aesthetics = await aestheticsQuery.get();

    if (aesthetics.isEmpty) return [];

    final templateIds = aesthetics.map((a) => a.templateId).toList();

    // Then get all entries for those templates
    final entriesQuery = _db.select(_db.logEntries)
      ..where((t) => t.templateId.isIn(templateIds))
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await entriesQuery.get();
    final entries = entities.map(_entityToModel).toList();

    return _loadContextForList(entries);
  }

  /// Get entries for templates with a specific aesthetic in a date range
  Future<List<LogEntryWithContext>> findByAestheticIconInRange(
    String icon,
    DateTime start,
    DateTime end,
  ) async {
    // First find all templates with this icon
    final aestheticsQuery = _db.select(_db.templateAesthetics)
      ..where((t) => t.icon.equals(icon));
    final aesthetics = await aestheticsQuery.get();

    if (aesthetics.isEmpty) return [];

    final templateIds = aesthetics.map((a) => a.templateId).toList();

    // Then get entries for those templates in the date range
    final entriesQuery = _db.select(_db.logEntries)
      ..where((t) => t.templateId.isIn(templateIds))
      ..where(
        (t) =>
            coalesce([
              t.occurredAt,
              t.scheduledFor,
            ]).isBiggerOrEqualValue(start) &
            coalesce([t.occurredAt, t.scheduledFor]).isSmallerOrEqualValue(end),
      )
      ..orderBy([
        (t) => OrderingTerm(
          expression: coalesce([t.occurredAt, t.scheduledFor]),
          mode: OrderingMode.desc,
        ),
      ]);
    final entities = await entriesQuery.get();
    final entries = entities.map(_entityToModel).toList();

    return _loadContextForList(entries);
  }

  /// Watch entries for templates with a specific aesthetic
  Stream<List<LogEntryWithContext>> watchByAestheticIcon(String icon) {
    // Watch aesthetics table for changes, then re-query
    return _db
        .select(_db.templateAesthetics)
        .watch()
        .asyncMap((_) => findByAestheticIcon(icon));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Count Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Count entries for a template
  Future<int> countByTemplateId(String templateId) async {
    final countExp = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)
      ..addColumns([countExp])
      ..where(_db.logEntries.templateId.equals(templateId));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Count all entries
  Future<int> countAll() async {
    final countExp = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Get entry count and last logged date for all templates in one query.
  Future<List<TemplateSummary>> getTemplateSummaries() async {
    final results = await _templateSummariesQuery().get();
    return _mapTemplateSummaries(results);
  }

  /// Watch entry count and last logged date for all templates.
  Stream<List<TemplateSummary>> watchTemplateSummaries() {
    return _templateSummariesQuery().watch().map(_mapTemplateSummaries);
  }

  JoinedSelectStatement _templateSummariesQuery() {
    final templateId = _db.logEntries.templateId;
    final countExp = _db.logEntries.id.count();
    final maxDateExp = coalesce([_db.logEntries.occurredAt, _db.logEntries.scheduledFor]).max();

    return _db.selectOnly(_db.logEntries)
      ..addColumns([templateId, countExp, maxDateExp])
      ..groupBy([templateId]);
  }

  List<TemplateSummary> _mapTemplateSummaries(List<TypedResult> results) {
    final templateId = _db.logEntries.templateId;
    final countExp = _db.logEntries.id.count();
    final maxDateExp = coalesce([_db.logEntries.occurredAt, _db.logEntries.scheduledFor]).max();

    return results.map((row) {
      return TemplateSummary(
        templateId: row.read(templateId)!,
        entryCount: row.read(countExp) ?? 0,
        lastLoggedAt: row.read(maxDateExp),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  LogEntryModel _entityToModel(LogEntry entity) {
    return LogEntryModel(
      id: entity.id,
      templateId: entity.templateId,
      scheduledFor: entity.scheduledFor,
      occurredAt: entity.occurredAt,
      data: entity.dataJson.isNotEmpty
          ? jsonDecode(entity.dataJson) as Map<String, dynamic>
          : {},
      updatedAt: entity.updatedAt,
    );
  }

  Future<LogEntryWithContext> _loadContext(LogEntryModel entry) async {
    // Load template
    final templateEntity = await (_db.select(
      _db.trackerTemplates,
    )..where((t) => t.id.equals(entry.templateId))).getSingleOrNull();

    if (templateEntity == null) {
      throw StateError(
        'Template ${entry.templateId} not found for entry ${entry.id}',
      );
    }

    final template = _templateEntityToModel(templateEntity);

    // Load aesthetics (optional)
    final aestheticsEntity = await (_db.select(
      _db.templateAesthetics,
    )..where((t) => t.templateId.equals(entry.templateId))).getSingleOrNull();
    final aesthetics = aestheticsEntity != null
        ? _aestheticsEntityToModel(aestheticsEntity)
        : null;

    // Load schedule (optional - find active schedule for this template)
    final scheduleEntity =
        await (_db.select(_db.schedules)
              ..where(
                (t) =>
                    t.templateId.equals(entry.templateId) &
                    t.isActive.equals(true),
              )
              ..limit(1))
            .getSingleOrNull();
    final schedule = scheduleEntity != null
        ? _scheduleEntityToModel(scheduleEntity)
        : null;

    return LogEntryWithContext(
      entry: entry,
      template: template,
      aesthetics: aesthetics,
      schedule: schedule,
    );
  }

  Future<List<LogEntryWithContext>> _loadContextForList(
    List<LogEntryModel> entries, {
    bool includeHidden = false,
  }) async {
    if (entries.isEmpty) return [];

    // Batch load all templates, aesthetics, and schedules
    final templateIds = entries.map((e) => e.templateId).toSet();

    // Load templates (filter by isHidden if needed)
    var templatesQuery = _db.select(_db.trackerTemplates)
      ..where((t) => t.id.isIn(templateIds));
    if (!includeHidden) {
      templatesQuery = templatesQuery..where((t) => t.isHidden.equals(false));
    }
    final templates = await templatesQuery.get();
    final templateMap = {
      for (final t in templates) t.id: _templateEntityToModel(t),
    };

    // Load aesthetics
    final aesthetics = await (_db.select(
      _db.templateAesthetics,
    )..where((t) => t.templateId.isIn(templateIds))).get();
    final aestheticsMap = {
      for (final a in aesthetics) a.templateId: _aestheticsEntityToModel(a),
    };

    // Load active schedules
    final schedules =
        await (_db.select(_db.schedules)..where(
              (t) => t.templateId.isIn(templateIds) & t.isActive.equals(true),
            ))
            .get();
    final scheduleMap = {
      for (final s in schedules) s.templateId: _scheduleEntityToModel(s),
    };

    // Build results (skip entries whose template was filtered out)
    final results = <LogEntryWithContext>[];
    for (final entry in entries) {
      final template = templateMap[entry.templateId];
      if (template == null) {
        // Template was filtered out (hidden) or doesn't exist - skip this entry
        continue;
      }
      results.add(
        LogEntryWithContext(
          entry: entry,
          template: template,
          aesthetics: aestheticsMap[entry.templateId],
          schedule: scheduleMap[entry.templateId],
        ),
      );
    }
    return results;
  }

  TrackerTemplateModel _templateEntityToModel(TrackerTemplate entity) {
    return TrackerTemplateModel(
      id: entity.id,
      name: entity.name,
      fields: entity.fieldsJson.isNotEmpty
          ? (jsonDecode(entity.fieldsJson) as List)
                .map((json) => TemplateField.fromJson(json))
                .toList()
          : [],
      updatedAt: entity.updatedAt,
      isArchived: entity.isArchived,
      isHidden: entity.isHidden,
    );
  }

  TemplateAestheticsModel _aestheticsEntityToModel(TemplateAesthetic entity) {
    return TemplateAestheticsConversion.fromEntity(entity);
  }

  ScheduleModel _scheduleEntityToModel(Schedule entity) {
    return ScheduleModel(
      id: entity.id,
      templateId: entity.templateId,
      recurrenceRule: entity.recurrenceRule,
      reminderOffsetMinutes: entity.reminderOffsetMinutes,
      isActive: entity.isActive,
      lastGeneratedAt: entity.lastGeneratedAt,
      updatedAt: entity.updatedAt,
    );
  }
}
