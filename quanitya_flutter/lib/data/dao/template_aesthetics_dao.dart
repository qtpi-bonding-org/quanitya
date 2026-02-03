import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';

/// Simple DAO for TemplateAesthetics - NO E2EE required.
///
/// Handles CRUD operations for template visual styling data.
/// This data is not PII so it syncs directly without encryption.
@lazySingleton
class TemplateAestheticsDao {
  final AppDatabase db;

  TemplateAestheticsDao(this.db);

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Insert a new aesthetics record
  /// Note: template_aesthetics is a PowerSync view, so we use INSERT OR REPLACE
  Future<void> insert(TemplateAestheticsModel model) async {
    final id = model.id.isEmpty ? const Uuid().v4() : model.id;
    final updatedAt = DateTime.now().toIso8601String();
    
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO template_aesthetics 
      (id, template_id, theme_name, icon, emoji, palette_json, font_config_json, color_mappings_json, container_style, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        model.templateId,
        model.themeName,
        model.icon,
        model.emoji,
        model.paletteJson,
        model.fontConfigJson,
        model.colorMappingsJson,
        model.containerStyle?.name,
        updatedAt,
      ],
    );
  }

  /// Update an existing aesthetics record
  /// Note: template_aesthetics is a PowerSync view, so we use raw SQL UPDATE
  Future<void> update(TemplateAestheticsModel model) async {
    final updatedAt = DateTime.now().toIso8601String();
    
    await db.customStatement(
      '''
      UPDATE template_aesthetics SET
        template_id = ?,
        theme_name = ?,
        icon = ?,
        emoji = ?,
        palette_json = ?,
        font_config_json = ?,
        color_mappings_json = ?,
        container_style = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        model.templateId,
        model.themeName,
        model.icon,
        model.emoji,
        model.paletteJson,
        model.fontConfigJson,
        model.colorMappingsJson,
        model.containerStyle?.name,
        updatedAt,
        model.id,
      ],
    );
  }

  /// Insert or update (upsert)
  /// Note: template_aesthetics is a PowerSync view, so we use INSERT OR REPLACE
  Future<void> upsert(TemplateAestheticsModel model) async {
    debugPrint('📦 TemplateAestheticsDao.upsert:');
    debugPrint('📦   id: ${model.id}');
    debugPrint('📦   templateId: ${model.templateId}');
    debugPrint('📦   icon: ${model.icon}');
    debugPrint('📦   emoji: ${model.emoji}');
    debugPrint('📦   containerStyle: ${model.containerStyle?.name}');

    final id = model.id.isEmpty ? const Uuid().v4() : model.id;
    final updatedAt = DateTime.now();
    
    // PowerSync views don't support ON CONFLICT, use INSERT OR REPLACE
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO template_aesthetics 
      (id, template_id, theme_name, icon, emoji, palette_json, font_config_json, color_mappings_json, container_style, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        model.templateId,
        model.themeName,
        model.icon,
        model.emoji,
        model.paletteJson,
        model.fontConfigJson,
        model.colorMappingsJson,
        model.containerStyle?.name,
        updatedAt.toIso8601String(),
      ],
    );
    debugPrint('📦   upsert complete');
  }

  /// Delete by ID
  /// Note: template_aesthetics is a PowerSync view, so we use raw SQL DELETE
  Future<int> delete(String id) async {
    await db.customStatement(
      'DELETE FROM template_aesthetics WHERE id = ?',
      [id],
    );
    return 1; // customStatement doesn't return affected rows
  }

  /// Delete by template ID
  /// Note: template_aesthetics is a PowerSync view, so we use raw SQL DELETE
  Future<int> deleteByTemplateId(String templateId) async {
    await db.customStatement(
      'DELETE FROM template_aesthetics WHERE template_id = ?',
      [templateId],
    );
    return 1; // customStatement doesn't return affected rows
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Query Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Find by ID
  Future<TemplateAestheticsModel?> findById(String id) async {
    final query = db.select(db.templateAesthetics)
      ..where((t) => t.id.equals(id));
    final entity = await query.getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Find by template ID (1:1 relationship)
  Future<TemplateAestheticsModel?> findByTemplateId(String templateId) async {
    final query = db.select(db.templateAesthetics)
      ..where((t) => t.templateId.equals(templateId));
    final entity = await query.getSingleOrNull();
    return entity != null ? _entityToModel(entity) : null;
  }

  /// Get all aesthetics records
  Future<List<TemplateAestheticsModel>> findAll() async {
    final entities = await db.select(db.templateAesthetics).get();
    return entities.map(_entityToModel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Operations (for reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watch aesthetics for a specific template
  Stream<TemplateAestheticsModel?> watchByTemplateId(String templateId) {
    final query = db.select(db.templateAesthetics)
      ..where((t) => t.templateId.equals(templateId));
    return query.watchSingleOrNull().map(
      (entity) => entity != null ? _entityToModel(entity) : null,
    );
  }

  /// Watch all aesthetics records
  Stream<List<TemplateAestheticsModel>> watchAll() {
    return db
        .select(db.templateAesthetics)
        .watch()
        .map(
          (entities) => entities.map(_entityToModel).toList(),
        );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Conversion Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Convert Drift entity to model (used for reads)
  TemplateAestheticsModel _entityToModel(TemplateAesthetic entity) {
    return TemplateAestheticsConversion.fromEntity(entity);
  }
}