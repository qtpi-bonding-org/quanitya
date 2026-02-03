import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/templates/models/shared/tracker_template.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// TrackerTemplate DualDao - handles atomic writes to tracker_templates ↔ encrypted_templates
///
/// Write-only DAO for E2EE operations. Read operations should query
/// the database directly via repositories.
@lazySingleton
class TrackerTemplateDualDao
    extends DualDao<TrackerTemplate, EncryptedTemplate> {
  TrackerTemplateDualDao(
    AppDatabase db,
    IDataEncryptionService encryption,
  ) : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.trackerTemplate(db),
      );

  @override
  Map<String, dynamic> entityToJson(TrackerTemplate entity) {
    final model = TrackerTemplateModel(
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
    return model.toJson();
  }

  @override
  Insertable<TrackerTemplate> entityToInsertable(TrackerTemplate entity) {
    return TrackerTemplatesCompanion(
      id: Value(entity.id),
      name: Value(entity.name),
      fieldsJson: Value(entity.fieldsJson),
      updatedAt: Value(entity.updatedAt),
      isArchived: Value(entity.isArchived),
      isHidden: Value(entity.isHidden),
    );
  }

  @override
  TrackerTemplate ensureEntityHasUUID(TrackerTemplate entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  TrackerTemplate applyTimestamp(TrackerTemplate entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert TrackerTemplateModel to Drift TrackerTemplate entity
  TrackerTemplate modelToEntity(TrackerTemplateModel model) {
    return TrackerTemplate(
      id: model.id,
      name: model.name,
      fieldsJson: jsonEncode(
        model.fields.map((field) => field.toJson()).toList(),
      ),
      updatedAt: model.updatedAt,
      isArchived: model.isArchived,
      isHidden: model.isHidden,
    );
  }

  /// Convert Drift TrackerTemplate entity to TrackerTemplateModel
  TrackerTemplateModel entityToModel(TrackerTemplate entity) {
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
}
