import 'package:injectable/injectable.dart';

import '../dao/schedule_dual_dao.dart';
import '../dao/schedule_query_dao.dart';
import '../../logic/schedules/models/schedule.dart';

/// Repository for ScheduleModel operations.
///
/// Uses ScheduleDualDao for writes (E2EE) and ScheduleQueryDao for reads.
/// All write operations use upsert for atomic local + encrypted table writes.
@lazySingleton
class ScheduleRepository {
  final ScheduleDualDao _writeDao;
  final ScheduleQueryDao _queryDao;

  ScheduleRepository(this._writeDao, this._queryDao);

  // ─────────────────────────────────────────────────────────────────────────
  // Stream-based queries (reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<ScheduleModel>> watchSchedulesForTemplate(String templateId) {
    return _queryDao.watchByTemplateId(templateId);
  }

  Stream<List<ScheduleModel>> watchActiveSchedules() {
    return _queryDao.watchActive();
  }

  Stream<List<ScheduleModel>> watchAllSchedules() {
    return _queryDao.watchAll();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Single-shot queries
  // ─────────────────────────────────────────────────────────────────────────

  Future<ScheduleModel?> getSchedule(String id) async {
    return _queryDao.findById(id);
  }

  Future<List<ScheduleModel>> getSchedulesForTemplate(String templateId) async {
    return _queryDao.findByTemplateId(templateId);
  }

  Future<List<ScheduleModel>> getActiveSchedulesForTemplate(String templateId) async {
    return _queryDao.findActiveByTemplateId(templateId);
  }

  Future<List<ScheduleModel>> getSchedulesNeedingGeneration(DateTime cutoff) async {
    return _queryDao.findNeedingGeneration(cutoff);
  }

  Future<List<ScheduleModel>> getSchedulesWithReminders() async {
    return _queryDao.findWithReminders();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write operations (E2EE via Dual DAO - upsert only)
  // ─────────────────────────────────────────────────────────────────────────

  /// Save a schedule (insert or update). Uses upsert for E2EE atomic writes.
  Future<void> save(ScheduleModel schedule) async {
    final entity = _writeDao.modelToEntity(
      schedule.copyWith(updatedAt: DateTime.now()),
    );
    await _writeDao.upsert(entity);
  }

  /// Delete a schedule by ID from both local and encrypted tables.
  Future<void> delete(String id) async {
    await _writeDao.delete(id);
  }

  /// Delete all schedules for a template.
  Future<int> deleteAllForTemplate(String templateId) async {
    final schedules = await _queryDao.findByTemplateId(templateId);
    for (final schedule in schedules) {
      await _writeDao.delete(schedule.id);
    }
    return schedules.length;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience operations (all use upsert internally)
  // ─────────────────────────────────────────────────────────────────────────

  /// Pause a schedule (set isActive = false).
  Future<void> pause(String id) async {
    final schedule = await _queryDao.findById(id);
    if (schedule != null) {
      await save(schedule.copyWith(isActive: false));
    }
  }

  /// Resume a schedule (set isActive = true).
  Future<void> resume(String id) async {
    final schedule = await _queryDao.findById(id);
    if (schedule != null) {
      await save(schedule.copyWith(isActive: true));
    }
  }

  /// Mark schedule as generated at a specific time.
  Future<void> markGenerated(String id, DateTime generatedAt) async {
    final schedule = await _queryDao.findById(id);
    if (schedule != null) {
      await save(schedule.copyWith(lastGeneratedAt: generatedAt));
    }
  }

}
