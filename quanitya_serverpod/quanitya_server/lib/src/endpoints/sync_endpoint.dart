import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Sync endpoint for PowerSync data operations
///
/// Handles CRUD operations for E2EE encrypted data and template aesthetics.
/// All operations require authentication via AnonAccred device key.
class SyncEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  // ─────────────────────────────────────────────────────────────────────────
  // Encrypted Templates
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted template
  ///
  /// Creates or updates an encrypted template record.
  /// Client-side UUID is used as the primary identifier.
  Future<EncryptedTemplate> upsertEncryptedTemplate(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: upsertEncryptedTemplate called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    // Check if template exists
    final existing = await EncryptedTemplate.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
      session.log(
        'SyncEndpoint: Updating existing template for id: $id',
        level: LogLevel.info,
      );
      // Update existing
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.updateRow(session, updated);
      session.log(
        'SyncEndpoint: Successfully updated template for id: $id',
        level: LogLevel.info,
      );
      return result;
    } else {
      session.log(
        'SyncEndpoint: Creating new template for id: $id',
        level: LogLevel.info,
      );
      // Create new
      final template = EncryptedTemplate(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.insertRow(session, template);
      session.log(
        'SyncEndpoint: Successfully inserted new template for id: $id',
        level: LogLevel.info,
      );
      return result;
    }
  }

  /// Delete encrypted template
  Future<bool> deleteEncryptedTemplate(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: deleteEncryptedTemplate called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplate.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      session.log(
        'SyncEndpoint: WARNING - Template not found or unauthorized for deletion: id=$id, accountId=$accountId',
        level: LogLevel.warning,
      );
      return false;
    }

    await EncryptedTemplate.db.deleteRow(session, existing);
    session.log(
      'SyncEndpoint: Successfully deleted template for id: $id',
      level: LogLevel.info,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Encrypted Entries
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted entry
  Future<EncryptedEntry> upsertEncryptedEntry(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: upsertEncryptedEntry called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
      session.log(
        'SyncEndpoint: Updating existing entry for id: $id',
        level: LogLevel.info,
      );
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.updateRow(session, updated);
      session.log(
        'SyncEndpoint: Successfully updated entry for id: $id',
        level: LogLevel.info,
      );
      return result;
    } else {
      session.log(
        'SyncEndpoint: Creating new entry for id: $id',
        level: LogLevel.info,
      );
      final entry = EncryptedEntry(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.insertRow(session, entry);
      session.log(
        'SyncEndpoint: Successfully inserted new entry for id: $id',
        level: LogLevel.info,
      );
      return result;
    }
  }

  /// Delete encrypted entry
  Future<bool> deleteEncryptedEntry(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: deleteEncryptedEntry called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      session.log(
        'SyncEndpoint: WARNING - Entry not found or unauthorized for deletion: id=$id, accountId=$accountId',
        level: LogLevel.warning,
      );
      return false;
    }

    await EncryptedEntry.db.deleteRow(session, existing);
    session.log(
      'SyncEndpoint: Successfully deleted entry for id: $id',
      level: LogLevel.info,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Encrypted Schedules
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted schedule
  Future<EncryptedSchedule> upsertEncryptedSchedule(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: upsertEncryptedSchedule called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
      session.log(
        'SyncEndpoint: Updating existing schedule for id: $id',
        level: LogLevel.info,
      );
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.updateRow(session, updated);
      session.log(
        'SyncEndpoint: Successfully updated schedule for id: $id',
        level: LogLevel.info,
      );
      return result;
    } else {
      session.log(
        'SyncEndpoint: Creating new schedule for id: $id',
        level: LogLevel.info,
      );
      final schedule = EncryptedSchedule(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.insertRow(session, schedule);
      session.log(
        'SyncEndpoint: Successfully inserted new schedule for id: $id',
        level: LogLevel.info,
      );
      return result;
    }
  }

  /// Delete encrypted schedule
  Future<bool> deleteEncryptedSchedule(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: deleteEncryptedSchedule called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      session.log(
        'SyncEndpoint: WARNING - Schedule not found or unauthorized for deletion: id=$id, accountId=$accountId',
        level: LogLevel.warning,
      );
      return false;
    }

    await EncryptedSchedule.db.deleteRow(session, existing);
    session.log(
      'SyncEndpoint: Successfully deleted schedule for id: $id',
      level: LogLevel.info,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template Aesthetics (non-E2EE)
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert template aesthetics
  Future<TemplateAesthetics> upsertTemplateAesthetics(
    Session session,
    String id,
    String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    String? updatedAt,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: upsertTemplateAesthetics called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    // Check if aesthetics record exists by ID
    final existing = await TemplateAesthetics.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
      session.log(
        'SyncEndpoint: Updating existing aesthetics for id: $id',
        level: LogLevel.info,
      );
      final updated = existing.copyWith(
        templateId: templateId,
        themeName: themeName,
        icon: icon,
        emoji: emoji,
        paletteJson: paletteJson,
        fontConfigJson: fontConfigJson,
        colorMappingsJson: colorMappingsJson,
        updatedAt: updatedAt != null
            ? DateTime.parse(updatedAt)
            : DateTime.now(),
      );
      final result = await TemplateAesthetics.db.updateRow(session, updated);
      session.log(
        'SyncEndpoint: Successfully updated aesthetics for id: $id',
        level: LogLevel.info,
      );
      return result;
    } else {
      session.log(
        'SyncEndpoint: Creating new aesthetics for id: $id',
        level: LogLevel.info,
      );
      final aesthetics = TemplateAesthetics(
        id: uuidId,
        accountId: accountId,
        templateId: templateId,
        themeName: themeName,
        icon: icon,
        emoji: emoji,
        paletteJson: paletteJson,
        fontConfigJson: fontConfigJson,
        colorMappingsJson: colorMappingsJson,
        updatedAt: updatedAt != null
            ? DateTime.parse(updatedAt)
            : DateTime.now(),
      );
      final result = await TemplateAesthetics.db.insertRow(session, aesthetics);
      session.log(
        'SyncEndpoint: Successfully inserted new aesthetics for id: $id',
        level: LogLevel.info,
      );
      return result;
    }
  }

  /// Delete template aesthetics
  Future<bool> deleteTemplateAesthetics(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    session.log(
      'SyncEndpoint: deleteTemplateAesthetics called for id: $id by accountId: $accountId',
      level: LogLevel.info,
    );
    final uuidId = UuidValue.fromString(id);

    final existing = await TemplateAesthetics.db.findById(session, uuidId);

    if (existing == null || existing.accountId != accountId) {
      session.log(
        'SyncEndpoint: WARNING - Aesthetics not found or unauthorized for deletion: id=$id, accountId=$accountId',
        level: LogLevel.warning,
      );
      return false;
    }

    await TemplateAesthetics.db.deleteRow(session, existing);
    session.log(
      'SyncEndpoint: Successfully deleted aesthetics for id: $id',
      level: LogLevel.info,
    );
    return true;
  }
}
