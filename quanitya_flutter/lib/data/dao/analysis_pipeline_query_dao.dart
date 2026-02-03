import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/analytics/models/analysis_pipeline.dart';
import '../../logic/analytics/models/analysis_enums.dart';
import '../../logic/analytics/enums/analysis_output_mode.dart';

/// Read-only DAO for analysis pipeline queries.
///
/// Provides efficient queries for analysis pipelines.
/// For write operations, use AnalysisPipelineDualDao.
@lazySingleton
class AnalysisPipelineQueryDao {
  final AppDatabase _db;

  AnalysisPipelineQueryDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Single Pipeline Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a pipeline by ID
  Future<AnalysisPipelineModel?> findById(String id) async {
    final entity = await (_db.select(
      _db.analysisPipelines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get a pipeline by name
  Future<AnalysisPipelineModel?> findByName(String name) async {
    final entity = await (_db.select(
      _db.analysisPipelines,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Find all pipelines, ordered by updatedAt descending
  Future<List<AnalysisPipelineModel>> findAll() async {
    final query = _db.select(_db.analysisPipelines)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Find pipelines for a specific field
  Future<List<AnalysisPipelineModel>> findByFieldId(String fieldId) async {
    final query = _db.select(_db.analysisPipelines)
      ..where((t) => t.fieldId.equals(fieldId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch a single pipeline by ID
  Stream<AnalysisPipelineModel?> watchById(String id) {
    return (_db.select(_db.analysisPipelines)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _entityToModel(entity) : null);
  }

  /// Watch all pipelines
  Stream<List<AnalysisPipelineModel>> watchAll() {
    final query = _db.select(_db.analysisPipelines)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch pipelines for a specific field
  Stream<List<AnalysisPipelineModel>> watchByFieldId(String fieldId) {
    final query = _db.select(_db.analysisPipelines)
      ..where((t) => t.fieldId.equals(fieldId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Count Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Count all pipelines
  Future<int> count() async {
    final countExp = _db.analysisPipelines.id.count();
    final query = _db.selectOnly(_db.analysisPipelines)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Count pipelines for a specific field
  Future<int> countByFieldId(String fieldId) async {
    final countExp = _db.analysisPipelines.id.count();
    final query = _db.selectOnly(_db.analysisPipelines)
      ..addColumns([countExp])
      ..where(_db.analysisPipelines.fieldId.equals(fieldId));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  AnalysisPipelineModel _entityToModel(AnalysisPipeline entity) {
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
