import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/analytics/models/analysis_script.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// AnalysisScript DualDao - handles atomic writes to analysis_scripts ↔ encrypted_analysis_scripts
///
/// Write-only DAO for E2EE operations. Read operations should use
/// AnalysisScriptQueryDao or query the database directly via repositories.
@injectable
class AnalysisScriptDualDao
    extends DualDao<AnalysisScript, EncryptedAnalysisScript> {
  AnalysisScriptDualDao(AppDatabase db, IDataEncryptionService encryption)
    : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.analysisScript(db),
      );

  @override
  Map<String, dynamic> entityToJson(AnalysisScript entity) {
    final model = entityToModel(entity);
    return model.toJson();
  }

  @override
  Insertable<AnalysisScript> entityToInsertable(AnalysisScript entity) {
    return AnalysisScriptsCompanion.insert(
      id: entity.id,
      name: entity.name,
      fieldId: entity.fieldId,
      outputMode: entity.outputMode,
      snippetLanguage: entity.snippetLanguage,
      snippet: entity.snippet,
      reasoning: Value(entity.reasoning),
      metadataJson: Value(entity.metadataJson),
      entryRangeStart: Value(entity.entryRangeStart),
      entryRangeEnd: Value(entity.entryRangeEnd),
      updatedAt: entity.updatedAt,
    );
  }

  @override
  AnalysisScript ensureEntityHasUUID(AnalysisScript entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  AnalysisScript applyTimestamp(AnalysisScript entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert AnalysisScriptModel to Drift AnalysisScript entity
  AnalysisScript modelToEntity(AnalysisScriptModel model) {
    return AnalysisScript(
      id: model.id,
      name: model.name,
      fieldId: model.fieldId,
      outputMode: model.outputMode,
      snippetLanguage: model.snippetLanguage,
      snippet: model.snippet,
      reasoning: model.reasoning,
      metadataJson: model.metadataJson,
      entryRangeStart: model.entryRangeStart,
      entryRangeEnd: model.entryRangeEnd,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert Drift AnalysisScript entity to AnalysisScriptModel
  AnalysisScriptModel entityToModel(AnalysisScript entity) {
    return AnalysisScriptModel(
      id: entity.id,
      name: entity.name,
      fieldId: entity.fieldId,
      outputMode: entity.outputMode,
      snippetLanguage: entity.snippetLanguage,
      snippet: entity.snippet,
      reasoning: entity.reasoning,
      metadataJson: entity.metadataJson,
      entryRangeStart: entity.entryRangeStart,
      entryRangeEnd: entity.entryRangeEnd,
      updatedAt: entity.updatedAt,
    );
  }
}
