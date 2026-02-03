import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/schedules/models/schedule.dart';

/// Read-only DAO for schedule queries.
///
/// Provides efficient queries for schedules.
/// For write operations, use ScheduleDualDao.
@lazySingleton
class ScheduleQueryDao {
  final AppDatabase _db;

  ScheduleQueryDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Single Schedule Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a schedule by ID
  Future<ScheduleModel?> findById(String id) async {
    final entity = await (_db.select(_db.schedules)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all schedules for a template
  Future<List<ScheduleModel>> findByTemplateId(String templateId) async {
    final query = _db.select(_db.schedules)
      ..where((t) => t.templateId.equals(templateId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get all active schedules
  Future<List<ScheduleModel>> findActive() async {
    final query = _db.select(_db.schedules)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get all active schedules for a template
  Future<List<ScheduleModel>> findActiveByTemplateId(String templateId) async {
    final query = _db.select(_db.schedules)
      ..where(
          (t) => t.templateId.equals(templateId) & t.isActive.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get all schedules
  Future<List<ScheduleModel>> findAll() async {
    final query = _db.select(_db.schedules)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get schedules that need entry generation
  Future<List<ScheduleModel>> findNeedingGeneration(DateTime cutoff) async {
    final query = _db.select(_db.schedules)
      ..where(
        (t) =>
            t.isActive.equals(true) &
            (t.lastGeneratedAt.isNull() |
                t.lastGeneratedAt.isSmallerThanValue(cutoff)),
      );
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Get schedules with reminders configured
  Future<List<ScheduleModel>> findWithReminders() async {
    final query = _db.select(_db.schedules)
      ..where(
          (t) => t.isActive.equals(true) & t.reminderOffsetMinutes.isNotNull());
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch a single schedule by ID
  Stream<ScheduleModel?> watchById(String id) {
    return (_db.select(_db.schedules)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _entityToModel(entity) : null);
  }

  /// Watch all schedules for a template
  Stream<List<ScheduleModel>> watchByTemplateId(String templateId) {
    final query = _db.select(_db.schedules)
      ..where((t) => t.templateId.equals(templateId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch all active schedules
  Stream<List<ScheduleModel>> watchActive() {
    final query = _db.select(_db.schedules)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch all schedules
  Stream<List<ScheduleModel>> watchAll() {
    final query = _db.select(_db.schedules)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  ScheduleModel _entityToModel(Schedule entity) {
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
