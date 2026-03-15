import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// TemplateAesthetics DualDao - handles atomic writes to template_aesthetics ↔ encrypted_template_aesthetics
///
/// Write-only DAO for E2EE operations. Read operations should query
/// the database directly via repositories.
@lazySingleton
class TemplateAestheticsDualDao extends DualDao<TemplateAesthetic, EncryptedTemplateAesthetic> {
  TemplateAestheticsDualDao(
    AppDatabase db,
    IDataEncryptionService encryption,
  ) : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.templateAesthetics(db),
      );

  @override
  Map<String, dynamic> entityToJson(TemplateAesthetic entity) {
    final model = TemplateAestheticsConversion.fromEntity(entity);
    return model.toJson();
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
  TemplateAesthetic ensureEntityHasUUID(TemplateAesthetic entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  TemplateAesthetic applyTimestamp(TemplateAesthetic entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert TemplateAestheticsModel to Drift TemplateAesthetic entity
  TemplateAesthetic modelToEntity(TemplateAestheticsModel model) {
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

  /// Convert Drift TemplateAesthetic entity to TemplateAestheticsModel
  TemplateAestheticsModel entityToModel(TemplateAesthetic entity) {
    return TemplateAestheticsConversion.fromEntity(entity);
  }
}
