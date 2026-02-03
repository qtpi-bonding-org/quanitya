import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/analytics/models/analysis_pipeline.dart';
import '../../logic/analytics/models/analysis_enums.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';
import 'dual_dao.dart';
import 'table_pairs.dart';

/// AnalysisPipeline DualDao - handles atomic writes to analysis_pipelines ↔ encrypted_analysis_pipelines
///
/// Write-only DAO for E2EE operations. Read operations should use
/// AnalysisPipelineQueryDao or query the database directly via repositories.
@injectable
class AnalysisPipelineDualDao
    extends DualDao<AnalysisPipeline, EncryptedAnalysisPipeline> {
  AnalysisPipelineDualDao(AppDatabase db, IDataEncryptionService encryption)
    : super(
        db: db,
        encryption: encryption,
        tables: TablePairs.analysisPipeline(db),
      );

  @override
  Map<String, dynamic> entityToJson(AnalysisPipeline entity) {
    final model = entityToModel(entity);
    return model.toJson();
  }

  @override
  Insertable<AnalysisPipeline> entityToInsertable(AnalysisPipeline entity) {
    return AnalysisPipelinesCompanion.insert(
      id: entity.id,
      name: entity.name,
      fieldId: entity.fieldId,
      outputMode: entity.outputMode,
      snippetLanguage: entity.snippetLanguage,
      snippet: entity.snippet,
      reasoning: Value(entity.reasoning),
      metadataJson: Value(entity.metadataJson),
      updatedAt: entity.updatedAt,
    );
  }

  @override
  AnalysisPipeline ensureEntityHasUUID(AnalysisPipeline entity) {
    if (entity.id.isEmpty) {
      return entity.copyWith(id: generateUUID());
    }
    return entity;
  }

  @override
  AnalysisPipeline applyTimestamp(AnalysisPipeline entity, DateTime timestamp) {
    return entity.copyWith(updatedAt: timestamp);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model/Entity Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert AnalysisPipelineModel to Drift AnalysisPipeline entity
  AnalysisPipeline modelToEntity(AnalysisPipelineModel model) {
    return AnalysisPipeline(
      id: model.id,
      name: model.name,
      fieldId: model.fieldId,
      outputMode: model.outputMode,
      snippetLanguage: model.snippetLanguage,
      snippet: model.snippet,
      reasoning: model.reasoning,
      metadataJson: model.metadataJson,
      updatedAt: model.updatedAt,
    );
  }

  /// Convert Drift AnalysisPipeline entity to AnalysisPipelineModel
  AnalysisPipelineModel entityToModel(AnalysisPipeline entity) {
    return AnalysisPipelineModel(
      id: entity.id,
      name: entity.name,
      fieldId: entity.fieldId,
      outputMode: entity.outputMode,
      snippetLanguage: entity.snippetLanguage,
      snippet: entity.snippet,
      reasoning: entity.reasoning,
      metadataJson: entity.metadataJson,
      updatedAt: entity.updatedAt,
    );
  }
}
