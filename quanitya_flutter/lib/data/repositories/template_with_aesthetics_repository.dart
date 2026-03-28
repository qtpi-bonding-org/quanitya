import '../../infrastructure/core/try_operation.dart';
import '../../logic/templates/services/engine/json_to_model_parser.dart';
import '../../infrastructure/webhooks/webhook_repository.dart';
import '../dao/template_aesthetics_dual_dao.dart';
import '../dao/tracker_template_dual_dao.dart';
import '../dao/template_query_dao.dart';
import '../dao/dual_dao.dart';
import '../db/app_database.dart';
import '../../logic/templates/models/shared/template_aesthetics.dart';
import '../../logic/templates/models/shared/tracker_template.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// General exception for template repository operations.
class TemplateRepositoryException implements Exception {
  final String message;
  final Object? cause;

  TemplateRepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'TemplateRepositoryException: $message';
}

/// Thrown when a schema change violates data integrity rules.
class SchemaChangeException implements Exception {
  final String message;
  final List<String> violations;

  SchemaChangeException(this.message, [this.violations = const []]);

  @override
  String toString() => 'SchemaChangeException: $message'
      '${violations.isNotEmpty ? '\nViolations: ${violations.join(", ")}' : ''}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Classes
// ─────────────────────────────────────────────────────────────────────────────

/// Combined template + aesthetics data for unified operations.
class TemplateWithAesthetics {
  final TrackerTemplateModel template;
  final TemplateAestheticsModel aesthetics; // Required for app usage

  const TemplateWithAesthetics({
    required this.template,
    required this.aesthetics, // Required
  });

  /// Create from ParsedAiTemplate (AI generation result)
  factory TemplateWithAesthetics.fromParsed(ParsedAiTemplate parsed) {
    return TemplateWithAesthetics(
      template: parsed.template,
      aesthetics: parsed.aesthetics,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

/// Repository that wraps TrackerTemplateDualDao + TemplateAestheticsDualDao.
///
/// Uses DualDao for writes (E2EE) and TemplateQueryDao for reads.
/// - TrackerTemplate: Uses DualDAO for writes (E2EE for PII)
/// - TemplateAesthetics: Uses DualDAO for writes (E2EE)
///
/// ## Schema Change Rules
///
/// When updating an existing template, the following rules apply to fields:
///
/// | Operation    | Allowed | Notes                                      |
/// |--------------|---------|-------------------------------------------|
/// | ADD field    | ✅      | Old logs show null, new logs can fill it  |
/// | DELETE field | ✅      | Set isDeleted=true, hidden from new logs  |
/// | RENAME field | ✅      | Update label, ID stays same               |
/// | REORDER      | ✅      | Just array order change                   |
/// | CHANGE TYPE  | ❌      | Blocked - would break existing log data   |
///
/// All write operations are atomic via database transactions.
class TemplateWithAestheticsRepository {
  final DualDao<TrackerTemplate, EncryptedTemplate> _dualDao;
  final TemplateAestheticsDualDao _aestheticsDualDao;
  final TemplateQueryDao _queryDao;
  final WebhookRepository _webhookRepo;

  TemplateWithAestheticsRepository(
    this._dualDao,
    this._aestheticsDualDao,
    this._queryDao,
    this._webhookRepo,
  );

  /// Get the concrete DAO for model conversion helpers.
  TrackerTemplateDualDao get _templateDao => _dualDao as TrackerTemplateDualDao;

  // ─────────────────────────────────────────────────────────────────────────
  // Save Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Saves both template and aesthetics as a unit.
  ///
  /// For updates (template ID exists), validates schema changes:
  /// - ✅ ADD field: Allowed (old logs show null for new field)
  /// - ✅ DELETE field: Allowed (set isDeleted=true, preserves history)
  /// - ✅ RENAME field: Allowed (label change, ID stays same)
  /// - ✅ REORDER fields: Allowed (just array order)
  /// - ❌ CHANGE TYPE: Blocked (would break existing log data)
  ///
  /// Throws [SchemaChangeException] if type change is attempted.
  Future<void> save(TemplateWithAesthetics data) {
    return tryMethod(
      () async {
        // Check if this is an update (template already exists)
        final existing = await findById(data.template.id);

        if (existing != null) {
          // UPDATE: Validate schema changes
          _validateSchemaChanges(existing.template, data.template);
        }

        // Save both template and aesthetics atomically
        await _dualDao.runInTransaction(() async {
          // Save template via DualDAO (handles E2EE internally)
          final entity = _templateDao.modelToEntity(data.template);
          await _dualDao.upsert(entity);

          // Save aesthetics via DualDAO (handles E2EE internally)
          final aestheticsEntity = _aestheticsDualDao.modelToEntity(data.aesthetics);
          _aestheticsDualDao.useTransaction = false;
          try {
            await _aestheticsDualDao.upsert(aestheticsEntity);
          } finally {
            _aestheticsDualDao.useTransaction = true;
          }
        });
      },
      TemplateRepositoryException.new,
      'save',
    );
  }

  /// Saves from ParsedAiTemplate directly (convenience method).
  Future<void> saveFromParsed(ParsedAiTemplate parsed) {
    return tryMethod(
      () async => save(TemplateWithAesthetics.fromParsed(parsed)),
      TemplateRepositoryException.new,
      'saveFromParsed',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Schema Validation
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates schema changes between old and new template.
  ///
  /// Rules:
  /// - ADD field: ✅ New field ID not in old → allowed
  /// - DELETE field: ✅ Old field marked isDeleted=true → allowed
  /// - RENAME field: ✅ Same ID, different label → allowed
  /// - REORDER: ✅ Same fields, different order → allowed
  /// - CHANGE TYPE: ❌ Same ID, different type → BLOCKED
  ///
  /// Throws [SchemaChangeException] if any type changes detected.
  void _validateSchemaChanges(
    TrackerTemplateModel oldTemplate,
    TrackerTemplateModel newTemplate,
  ) {
    final oldFieldsById = {for (final f in oldTemplate.fields) f.id: f};
    final typeChangeViolations = <String>[];

    for (final newField in newTemplate.fields) {
      final oldField = oldFieldsById[newField.id];
      
      if (oldField == null) {
        // ADD: New field ID not in old template → allowed
        continue;
      }

      // Field exists in both old and new - check for type change
      if (oldField.type != newField.type) {
        // CHANGE TYPE: ❌ BLOCKED
        typeChangeViolations.add(
          'Field "${newField.label}" (${newField.id}): '
          '${oldField.type.name} → ${newField.type.name}',
        );
      }
    }

    // Throw if any type changes detected
    if (typeChangeViolations.isNotEmpty) {
      throw SchemaChangeException(
        'Cannot change field types on existing template. '
        'This would break existing log entries.',
        typeChangeViolations,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads template with its aesthetics by template ID.
  ///
  /// Returns null if template doesn't exist.
  /// Returns default aesthetics if aesthetics don't exist for the template.
  Future<TemplateWithAesthetics?> findById(String templateId) {
    return tryMethod(
      () async {
        final template = await _queryDao.findById(templateId);
        if (template == null) return null;

        final aesthetics =
            await _queryDao.findAestheticsById(templateId) ??
            TemplateAestheticsModel.defaults(templateId: templateId);

        return TemplateWithAesthetics(template: template, aesthetics: aesthetics);
      },
      TemplateRepositoryException.new,
      'findById',
    );
  }

  /// Loads templates with optional filters.
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
  Future<List<TemplateWithAesthetics>> find({
    bool? isArchived,
    bool? isHidden,
  }) {
    return tryMethod(
      () async {
        final templates = await _queryDao.find(
          isArchived: isArchived,
          isHidden: isHidden,
        );
        return _loadWithAesthetics(templates);
      },
      TemplateRepositoryException.new,
      'find',
    );
  }

  /// Helper to load aesthetics for a list of templates.
  Future<List<TemplateWithAesthetics>> _loadWithAesthetics(
    List<TrackerTemplateModel> templates,
  ) async {
    final results = <TemplateWithAesthetics>[];

    for (final template in templates) {
      final aesthetics =
          await _queryDao.findAestheticsById(template.id) ??
          TemplateAestheticsModel.defaults(templateId: template.id);

      results.add(
        TemplateWithAesthetics(
          template: template,
          aesthetics: aesthetics,
        ),
      );
    }

    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Archives a template (soft delete).
  ///
  /// Aesthetics are preserved for potential unarchive.
  /// Webhooks are disabled (not deleted) so they can be re-enabled on unarchive.
  Future<void> archive(String templateId) {
    return tryMethod(
      () async {
        final template = await _queryDao.findById(templateId);
        if (template != null) {
          final archived = template.copyWith(isArchived: true);
          final entity = _templateDao.modelToEntity(archived);
          await _dualDao.upsert(entity);

          // Disable webhooks for archived template
          await _webhookRepo.disableByTemplateId(templateId);
        }
      },
      TemplateRepositoryException.new,
      'archive',
    );
  }

  /// Unarchives a template.
  Future<void> unarchive(String templateId) {
    return tryMethod(
      () async {
        final template = await _queryDao.findById(templateId);
        if (template != null) {
          final unarchived = template.copyWith(isArchived: false);
          final entity = _templateDao.modelToEntity(unarchived);
          await _dualDao.upsert(entity);
        }
      },
      TemplateRepositoryException.new,
      'unarchive',
    );
  }

  /// Hides a template (requires authentication to view).
  ///
  /// Hidden templates and their entries are excluded from normal queries.
  /// Similar to iOS Hidden Photos or Locked Notes feature.
  Future<void> hide(String templateId) {
    return tryMethod(
      () async {
        final template = await _queryDao.findById(templateId);
        if (template != null) {
          final hidden = template.copyWith(isHidden: true);
          final entity = _templateDao.modelToEntity(hidden);
          await _dualDao.upsert(entity);
        }
      },
      TemplateRepositoryException.new,
      'hide',
    );
  }

  /// Unhides a template (makes it visible in normal queries).
  Future<void> unhide(String templateId) {
    return tryMethod(
      () async {
        final template = await _queryDao.findById(templateId);
        if (template != null) {
          final visible = template.copyWith(isHidden: false);
          final entity = _templateDao.modelToEntity(visible);
          await _dualDao.upsert(entity);
        }
      },
      TemplateRepositoryException.new,
      'unhide',
    );
  }

  /// Permanently deletes template and its aesthetics (atomic transaction).
  ///
  /// WARNING: This is destructive and cannot be undone.
  Future<void> deletePermanently(String templateId) {
    return tryMethod(
      () async {
        await _dualDao.runInTransaction(() async {
          // Find aesthetics for this template to get its ID
          final aesthetics = await _queryDao.findAestheticsById(templateId);
          if (aesthetics != null) {
            _aestheticsDualDao.useTransaction = false;
            try {
              await _aestheticsDualDao.delete(aesthetics.id);
            } finally {
              _aestheticsDualDao.useTransaction = true;
            }
          }
          await _dualDao.delete(templateId);
        });
      },
      TemplateRepositoryException.new,
      'deletePermanently',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stream Operations (for reactive UI)
  // ─────────────────────────────────────────────────────────────────────────

  /// Watches aesthetics for a specific template.
  Stream<TemplateAestheticsModel?> watchAestheticsById(String templateId) {
    return _queryDao.watchAestheticsById(templateId);
  }

  /// Watches templates with optional filters.
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
  Stream<List<TemplateWithAesthetics>> watch({
    bool? isArchived,
    bool? isHidden,
  }) {
    return _queryDao.watchWithAesthetics(
      isArchived: isArchived,
      isHidden: isHidden,
    ).map((rows) => rows.map((row) {
      return TemplateWithAesthetics(
        template: row.template,
        aesthetics: row.aesthetics ?? TemplateAestheticsModel.defaults(templateId: row.template.id),
      );
    }).toList());
  }

  /// Watches a single template with its aesthetics by ID.
  /// 
  /// Uses a Drift LEFT JOIN query for reactive updates.
  Stream<TemplateWithAesthetics?> watchById(String templateId) {
    return _queryDao.watchByIdWithAesthetics(templateId).map((row) {
      if (row == null) return null;
      return TemplateWithAesthetics(
        template: row.template,
        aesthetics: row.aesthetics ?? TemplateAestheticsModel.defaults(templateId: templateId),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Count Operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the count of templates with optional filters.
  ///
  /// Parameters:
  /// - `isArchived`: `null` = no filter, `true` = archived only, `false` = active only
  /// - `isHidden`: `null` = no filter, `true` = hidden only, `false` = visible only
  Future<int> count({
    bool? isArchived,
    bool? isHidden,
  }) {
    return tryMethod(
      () async => _queryDao.count(isArchived: isArchived, isHidden: isHidden),
      TemplateRepositoryException.new,
      'count',
    );
  }
}
