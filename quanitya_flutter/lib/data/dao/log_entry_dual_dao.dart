import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/log_entries/models/log_entry.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// LogEntry DualDao - handles atomic writes to log_entries ↔ encrypted_entries
///
/// Write-only DAO for E2EE operations. Read operations should use
/// LogEntryQueryDao or query the database directly via repositories.
@lazySingleton
class LogEntryDualDao extends DualDao<LogEntry, EncryptedEntry> {
  LogEntryDualDao(
    AppDatabase db,
    IDataEncryption encryption,
  ) : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.logEntry(db),
      );

  @override
  Map<String, dynamic> entityToJson(LogEntry entity) {
    final model = LogEntryModel(
      id: entity.id,
      templateId: entity.templateId,
      scheduledFor: entity.scheduledFor,
      occurredAt: entity.occurredAt,
      data: entity.dataJson.isNotEmpty
          ? jsonDecode(entity.dataJson) as Map<String, dynamic>
          : {},
      updatedAt: entity.updatedAt,
    );
    return model.toJson();
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
  LogEntry ensureEntityHasUUID(LogEntry entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  LogEntry applyTimestamp(LogEntry entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert LogEntryModel to Drift LogEntry entity
  LogEntry modelToEntity(LogEntryModel model) {
    return LogEntry(
      id: model.id,
      templateId: model.templateId,
      scheduledFor: model.scheduledFor,
      occurredAt: model.occurredAt,
      dataJson: jsonEncode(model.data),
      updatedAt: model.updatedAt,
    );
  }

  /// Convert Drift LogEntry entity to LogEntryModel
  LogEntryModel entityToModel(LogEntry entity) {
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
}
