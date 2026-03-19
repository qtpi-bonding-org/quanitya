import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/analysis/models/analysis_script.dart';

/// Read-only DAO for analysis script queries.
///
/// Provides efficient queries for analysis scripts.
/// For write operations, use AnalysisScriptDualDao.
@lazySingleton
class AnalysisScriptQueryDao {
  final AppDatabase _db;

  AnalysisScriptQueryDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Single Script Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a script by ID
  Future<AnalysisScriptModel?> findById(String id) async {
    final entity = await (_db.select(
      _db.analysisScripts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get a script by name
  Future<AnalysisScriptModel?> findByName(String name) async {
    final entity = await (_db.select(
      _db.analysisScripts,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Find all scripts, ordered by updatedAt descending
  Future<List<AnalysisScriptModel>> findAll() async {
    final query = _db.select(_db.analysisScripts)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  /// Find scripts for a specific field
  Future<List<AnalysisScriptModel>> findByFieldId(String fieldId) async {
    final query = _db.select(_db.analysisScripts)
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

  /// Watch a single script by ID
  Stream<AnalysisScriptModel?> watchById(String id) {
    return (_db.select(_db.analysisScripts)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _entityToModel(entity) : null);
  }

  /// Watch all scripts
  Stream<List<AnalysisScriptModel>> watchAll() {
    final query = _db.select(_db.analysisScripts)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  /// Watch scripts for a specific field
  Stream<List<AnalysisScriptModel>> watchByFieldId(String fieldId) {
    final query = _db.select(_db.analysisScripts)
      ..where((t) => t.fieldId.equals(fieldId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Count Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Count all scripts
  Future<int> count() async {
    final countExp = _db.analysisScripts.id.count();
    final query = _db.selectOnly(_db.analysisScripts)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  /// Count scripts for a specific field
  Future<int> countByFieldId(String fieldId) async {
    final countExp = _db.analysisScripts.id.count();
    final query = _db.selectOnly(_db.analysisScripts)
      ..addColumns([countExp])
      ..where(_db.analysisScripts.fieldId.equals(fieldId));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  AnalysisScriptModel _entityToModel(AnalysisScript entity) {
    return AnalysisScriptModel(
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
