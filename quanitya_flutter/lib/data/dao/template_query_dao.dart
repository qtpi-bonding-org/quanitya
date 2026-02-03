import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../db/app_database.dart';
import '../../logic/templates/models/shared/tracker_template.dart';
import '../../logic/templates/models/shared/template_field.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';

/// Result row from template + aesthetics join query
class TemplateWithAestheticsRow {
  final TrackerTemplateModel template;
  final TemplateAestheticsModel? aesthetics;

  const TemplateWithAestheticsRow({
    required this.template,
    this.aesthetics,
  });
}

/// Read-only DAO for template queries.
///
/// Provides efficient queries for templates and their aesthetics.
/// For write operations, use TrackerTemplateDualDao.
///
/// ## Query Parameters
/// 
/// Most query methods accept optional filter parameters:
/// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
/// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
///
/// Example usage:
/// ```dart
/// // Active, visible templates (normal use)
/// dao.find(isArchived: false, isHidden: false);
/// 
/// // Hidden templates only (authenticated access)
/// dao.find(isHidden: true);
/// 
/// // Everything, no filters
/// dao.find();
/// ```
@lazySingleton
class TemplateQueryDao {
  final AppDatabase _db;

  TemplateQueryDao(this._db);

  // ─────────────────────────────────────────────────────────────────────────
  // Single Template Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get a template by ID
  Future<TrackerTemplateModel?> findById(String id) async {
    final entity = await (_db.select(_db.trackerTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get a template by name
  Future<TrackerTemplateModel?> findByName(String name) async {
    final entity = await (_db.select(_db.trackerTemplates)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // List Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Find templates with optional filters.
  ///
  /// Parameters:
  /// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
  /// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
  ///
  /// Examples:
  /// ```dart
  /// find(isArchived: false, isHidden: false); // Active, visible (normal use)
  /// find(isHidden: true);                      // Hidden only (authenticated)
  /// find();                                    // Everything, no filters
  /// ```
  Future<List<TrackerTemplateModel>> find({
    bool? isArchived,
    bool? isHidden,
  }) async {
    var query = _db.select(_db.trackerTemplates);
    
    if (isArchived != null) {
      query = query..where((t) => t.isArchived.equals(isArchived));
    }
    if (isHidden != null) {
      query = query..where((t) => t.isHidden.equals(isHidden));
    }
    
    query = query..orderBy([
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);
    
    final entities = await query.get();
    return entities.map(_entityToModel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Queries (Reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch a single template by ID
  Stream<TrackerTemplateModel?> watchById(String id) {
    return (_db.select(_db.trackerTemplates)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((entity) => entity != null ? _entityToModel(entity) : null);
  }

  /// Watch templates with optional filters.
  ///
  /// Parameters:
  /// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
  /// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
  ///
  /// Examples:
  /// ```dart
  /// watch(isArchived: false, isHidden: false); // Active, visible (normal use)
  /// watch(isHidden: true);                      // Hidden only (authenticated)
  /// watch();                                    // Everything, no filters
  /// ```
  Stream<List<TrackerTemplateModel>> watch({
    bool? isArchived,
    bool? isHidden,
  }) {
    var query = _db.select(_db.trackerTemplates);
    
    if (isArchived != null) {
      query = query..where((t) => t.isArchived.equals(isArchived));
    }
    if (isHidden != null) {
      query = query..where((t) => t.isHidden.equals(isHidden));
    }
    
    query = query..orderBy([
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);
    
    return query.watch().map((rows) => rows.map(_entityToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Count Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Count templates with optional filters.
  ///
  /// Parameters:
  /// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
  /// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
  Future<int> count({
    bool? isArchived,
    bool? isHidden,
  }) async {
    final countExp = _db.trackerTemplates.id.count();
    final query = _db.selectOnly(_db.trackerTemplates)..addColumns([countExp]);
    
    if (isArchived != null) {
      query.where(_db.trackerTemplates.isArchived.equals(isArchived));
    }
    if (isHidden != null) {
      query.where(_db.trackerTemplates.isHidden.equals(isHidden));
    }
    
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Aesthetics Queries
  // ─────────────────────────────────────────────────────────────────────────

  /// Get aesthetics for a template
  Future<TemplateAestheticsModel?> findAestheticsById(String templateId) async {
    final entity = await (_db.select(_db.templateAesthetics)
          ..where((t) => t.templateId.equals(templateId)))
        .getSingleOrNull();
    return entity != null ? _aestheticsEntityToModel(entity) : null;
  }

  /// Watch aesthetics for a template
  Stream<TemplateAestheticsModel?> watchAestheticsById(String templateId) {
    return (_db.select(_db.templateAesthetics)
          ..where((t) => t.templateId.equals(templateId)))
        .watchSingleOrNull()
        .map((entity) =>
            entity != null ? _aestheticsEntityToModel(entity) : null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Join Queries (Template + Aesthetics combined)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch templates with their aesthetics using a LEFT JOIN.
  /// 
  /// This is more efficient than combining streams - single query watches both tables.
  ///
  /// Parameters:
  /// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
  /// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
  Stream<List<TemplateWithAestheticsRow>> watchWithAesthetics({
    bool? isArchived,
    bool? isHidden,
  }) {
    final query = _db.select(_db.trackerTemplates).join([
      leftOuterJoin(
        _db.templateAesthetics,
        _db.templateAesthetics.templateId.equalsExp(_db.trackerTemplates.id),
      ),
    ]);
    
    // Build filter expression
    Expression<bool>? filter;
    if (isArchived != null) {
      filter = _db.trackerTemplates.isArchived.equals(isArchived);
    }
    if (isHidden != null) {
      final hiddenFilter = _db.trackerTemplates.isHidden.equals(isHidden);
      filter = filter != null ? filter & hiddenFilter : hiddenFilter;
    }
    
    if (filter != null) {
      query.where(filter);
    }
    
    query.orderBy([OrderingTerm.desc(_db.trackerTemplates.updatedAt)]);

    return query.watch().map((rows) => rows.map((row) {
      final template = row.readTable(_db.trackerTemplates);
      final aesthetics = row.readTableOrNull(_db.templateAesthetics);
      return TemplateWithAestheticsRow(
        template: _entityToModel(template),
        aesthetics: aesthetics != null 
            ? _aestheticsEntityToModel(aesthetics)
            : null,
      );
    }).toList());
  }

  /// Watch a single template with its aesthetics by ID using a LEFT JOIN.
  Stream<TemplateWithAestheticsRow?> watchByIdWithAesthetics(String templateId) {
    final query = _db.select(_db.trackerTemplates).join([
      leftOuterJoin(
        _db.templateAesthetics,
        _db.templateAesthetics.templateId.equalsExp(_db.trackerTemplates.id),
      ),
    ])
      ..where(_db.trackerTemplates.id.equals(templateId));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final template = row.readTable(_db.trackerTemplates);
      final aesthetics = row.readTableOrNull(_db.templateAesthetics);
      return TemplateWithAestheticsRow(
        template: _entityToModel(template),
        aesthetics: aesthetics != null 
            ? _aestheticsEntityToModel(aesthetics)
            : null,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────

  TrackerTemplateModel _entityToModel(TrackerTemplate entity) {
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

  TemplateAestheticsModel _aestheticsEntityToModel(TemplateAesthetic entity) {
    return TemplateAestheticsConversion.fromEntity(entity);
  }
}
