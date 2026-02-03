import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../core/try_operation.dart';
import 'models/webhook_model.dart';
import 'webhook_exception.dart';

/// Repository for webhook CRUD operations.
/// 
/// Local-only storage (never synced). Webhooks are per-template.
@lazySingleton
class WebhookRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  WebhookRepository(this._db);

  /// Get all webhooks
  Future<List<WebhookModel>> getAll() {
    return tryMethod(
      () async {
        final rows = await _db.select(_db.webhooks).get();
        return rows.map(_rowToModel).toList();
      },
      WebhookException.new,
      'getAll',
    );
  }

  /// Get webhooks for a specific template
  Future<List<WebhookModel>> getByTemplateId(String templateId) {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.webhooks)
          ..where((t) => t.templateId.equals(templateId)))
          .get();
        return rows.map(_rowToModel).toList();
      },
      WebhookException.new,
      'getByTemplateId',
    );
  }

  /// Get enabled webhooks for a specific template (for triggering)
  Future<List<WebhookModel>> getEnabledByTemplateId(String templateId) {
    return tryMethod(
      () async {
        final rows = await (_db.select(_db.webhooks)
          ..where((t) => t.templateId.equals(templateId) & t.isEnabled.equals(true)))
          .get();
        return rows.map(_rowToModel).toList();
      },
      WebhookException.new,
      'getEnabledByTemplateId',
    );
  }

  /// Get webhook by ID
  Future<WebhookModel?> getById(String id) {
    return tryMethod(
      () async {
        final row = await (_db.select(_db.webhooks)
          ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
        return row != null ? _rowToModel(row) : null;
      },
      WebhookException.new,
      'getById',
    );
  }

  /// Create a new webhook
  Future<WebhookModel> create({
    required String templateId,
    required String name,
    required String url,
    String? apiKeyId,
    bool isEnabled = true,
  }) {
    return tryMethod(
      () async {
        // Validate URL
        final urlError = WebhookUrlValidator.validate(url);
        if (urlError != null) {
          throw WebhookException(urlError);
        }

        final id = _uuid.v4();
        final now = DateTime.now();

        final companion = WebhooksCompanion.insert(
          id: id,
          templateId: templateId,
          name: name,
          url: url,
          apiKeyId: Value(apiKeyId),
          isEnabled: Value(isEnabled),
          lastTriggeredAt: const Value(null),
          updatedAt: now,
        );
        await _db.into(_db.webhooks).insert(companion);

        return WebhookModel(
          id: id,
          templateId: templateId,
          name: name,
          url: url,
          apiKeyId: apiKeyId,
          isEnabled: isEnabled,
          lastTriggeredAt: null,
          updatedAt: now,
        );
      },
      WebhookException.new,
      'create',
    );
  }

  /// Update an existing webhook
  Future<WebhookModel> update({
    required String id,
    String? name,
    String? url,
    String? apiKeyId,
    bool? isEnabled,
  }) {
    return tryMethod(
      () async {
        final existing = await getById(id);
        if (existing == null) {
          throw WebhookException('Webhook not found: $id');
        }

        // Validate URL if provided
        if (url != null) {
          final urlError = WebhookUrlValidator.validate(url);
          if (urlError != null) {
            throw WebhookException(urlError);
          }
        }

        final now = DateTime.now();
        await (_db.update(_db.webhooks)..where((t) => t.id.equals(id))).write(
          WebhooksCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            url: url != null ? Value(url) : const Value.absent(),
            apiKeyId: Value(apiKeyId ?? existing.apiKeyId),
            isEnabled: isEnabled != null ? Value(isEnabled) : const Value.absent(),
            updatedAt: Value(now),
          ),
        );

        return WebhookModel(
          id: id,
          templateId: existing.templateId,
          name: name ?? existing.name,
          url: url ?? existing.url,
          apiKeyId: apiKeyId ?? existing.apiKeyId,
          isEnabled: isEnabled ?? existing.isEnabled,
          lastTriggeredAt: existing.lastTriggeredAt,
          updatedAt: now,
        );
      },
      WebhookException.new,
      'update',
    );
  }

  /// Update last triggered timestamp
  Future<void> updateLastTriggered(String id, DateTime triggeredAt) {
    return tryMethod(
      () async {
        await (_db.update(_db.webhooks)..where((t) => t.id.equals(id))).write(
          WebhooksCompanion(
            lastTriggeredAt: Value(triggeredAt),
          ),
        );
      },
      WebhookException.new,
      'updateLastTriggered',
    );
  }

  /// Delete a webhook
  Future<void> delete(String id) {
    return tryMethod(
      () async {
        await (_db.delete(_db.webhooks)..where((t) => t.id.equals(id))).go();
      },
      WebhookException.new,
      'delete',
    );
  }

  /// Delete all webhooks for a template (cascade delete)
  Future<void> deleteByTemplateId(String templateId) {
    return tryMethod(
      () async {
        await (_db.delete(_db.webhooks)..where((t) => t.templateId.equals(templateId))).go();
      },
      WebhookException.new,
      'deleteByTemplateId',
    );
  }

  /// Disable all webhooks for a template (on archive)
  Future<void> disableByTemplateId(String templateId) {
    return tryMethod(
      () async {
        await (_db.update(_db.webhooks)..where((t) => t.templateId.equals(templateId))).write(
          const WebhooksCompanion(
            isEnabled: Value(false),
          ),
        );
      },
      WebhookException.new,
      'disableByTemplateId',
    );
  }

  /// Convert database row to model
  WebhookModel _rowToModel(Webhook row) {
    return WebhookModel(
      id: row.id,
      templateId: row.templateId,
      name: row.name,
      url: row.url,
      apiKeyId: row.apiKeyId,
      isEnabled: row.isEnabled,
      lastTriggeredAt: row.lastTriggeredAt,
      updatedAt: row.updatedAt,
    );
  }
}
