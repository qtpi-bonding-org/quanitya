import 'package:injectable/injectable.dart';

import '../../infrastructure/core/try_operation.dart';
import '../../logic/schedules/exceptions/schedule_exceptions.dart';
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

  Future<ScheduleModel?> getSchedule(String id) {
    return tryMethod(
      () async => _queryDao.findById(id),
      ScheduleOperationException.new,
      'getSchedule',
    );
  }

  Future<List<ScheduleModel>> getSchedulesForTemplate(String templateId) {
    return tryMethod(
      () async => _queryDao.findByTemplateId(templateId),
      ScheduleOperationException.new,
      'getSchedulesForTemplate',
    );
  }

  Future<List<ScheduleModel>> getActiveSchedulesForTemplate(String templateId) {
    return tryMethod(
      () async => _queryDao.findActiveByTemplateId(templateId),
      ScheduleOperationException.new,
      'getActiveSchedulesForTemplate',
    );
  }

  Future<List<ScheduleModel>> getSchedulesNeedingGeneration(DateTime cutoff) {
    return tryMethod(
      () async => _queryDao.findNeedingGeneration(cutoff),
      ScheduleOperationException.new,
      'getSchedulesNeedingGeneration',
    );
  }

  Future<List<ScheduleModel>> getSchedulesWithReminders() {
    return tryMethod(
      () async => _queryDao.findWithReminders(),
      ScheduleOperationException.new,
      'getSchedulesWithReminders',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write operations (E2EE via Dual DAO - upsert only)
  // ─────────────────────────────────────────────────────────────────────────

  /// Save a schedule (insert or update). Uses upsert for E2EE atomic writes.
  Future<void> save(ScheduleModel schedule) {
    return tryMethod(
      () async {
        final entity = _writeDao.modelToEntity(
          schedule.copyWith(updatedAt: DateTime.now()),
        );
        await _writeDao.upsert(entity);
      },
      ScheduleOperationException.new,
      'save',
    );
  }

  /// Delete a schedule by ID from both local and encrypted tables.
  Future<void> delete(String id) {
    return tryMethod(
      () async => _writeDao.delete(id),
      ScheduleOperationException.new,
      'delete',
    );
  }

  /// Delete all schedules for a template.
  Future<int> deleteAllForTemplate(String templateId) {
    return tryMethod(
      () async {
        final schedules = await _queryDao.findByTemplateId(templateId);
        for (final schedule in schedules) {
          await _writeDao.delete(schedule.id);
        }
        return schedules.length;
      },
      ScheduleOperationException.new,
      'deleteAllForTemplate',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience operations (all use upsert internally)
  // ─────────────────────────────────────────────────────────────────────────

  /// Pause a schedule (set isActive = false).
  Future<void> pause(String id) {
    return tryMethod(
      () async {
        final schedule = await _queryDao.findById(id);
        if (schedule != null) {
          await save(schedule.copyWith(isActive: false));
        }
      },
      ScheduleOperationException.new,
      'pause',
    );
  }

  /// Resume a schedule (set isActive = true).
  Future<void> resume(String id) {
    return tryMethod(
      () async {
        final schedule = await _queryDao.findById(id);
        if (schedule != null) {
          await save(schedule.copyWith(isActive: true));
        }
      },
      ScheduleOperationException.new,
      'resume',
    );
  }

  /// Mark schedule as generated at a specific time.
  Future<void> markGenerated(String id, DateTime generatedAt) {
    return tryMethod(
      () async {
        final schedule = await _queryDao.findById(id);
        if (schedule != null) {
          await save(schedule.copyWith(lastGeneratedAt: generatedAt));
        }
      },
      ScheduleOperationException.new,
      'markGenerated',
    );
  }

}
