import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/schedules/models/schedule.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// Schedule DualDao - handles atomic writes to schedules ↔ encrypted_schedules
///
/// Write-only DAO for E2EE operations. Read operations should query
/// the database directly via repositories.
@lazySingleton
class ScheduleDualDao extends DualDao<Schedule, EncryptedSchedule> {
  ScheduleDualDao(
    AppDatabase db,
    IDataEncryptionService encryption,
  ) : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.schedule(db),
      );

  @override
  Map<String, dynamic> entityToJson(Schedule entity) {
    final model = ScheduleModel(
      id: entity.id,
      templateId: entity.templateId,
      recurrenceRule: entity.recurrenceRule,
      reminderOffsetMinutes: entity.reminderOffsetMinutes,
      isActive: entity.isActive,
      lastGeneratedAt: entity.lastGeneratedAt,
      updatedAt: entity.updatedAt,
    );
    return model.toJson();
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
  Schedule ensureEntityHasUUID(Schedule entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  Schedule applyTimestamp(Schedule entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert ScheduleModel to Drift Schedule entity
  Schedule modelToEntity(ScheduleModel model) {
    return Schedule(
      id: model.id,
      templateId: model.templateId,
      recurrenceRule: model.recurrenceRule,
      reminderOffsetMinutes: model.reminderOffsetMinutes,
      isActive: model.isActive,
      lastGeneratedAt: model.lastGeneratedAt,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert Drift Schedule entity to ScheduleModel
  ScheduleModel entityToModel(Schedule entity) {
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
