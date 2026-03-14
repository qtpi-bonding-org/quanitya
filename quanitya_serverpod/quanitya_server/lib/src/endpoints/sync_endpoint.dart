import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/storage_quota_service.dart';

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
  Future<EncryptedTemplate> upsertEncryptedTemplate(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplate.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountId == accountId
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountId, delta);
    }

    if (existing != null && existing.accountId == accountId) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountId, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final template = EncryptedTemplate(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.insertRow(session, template);
      await StorageQuotaService.incrementUsage(
        session, accountId, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted template
  Future<bool> deleteEncryptedTemplate(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplate.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedTemplate.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountId, removedSize, 1,
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
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountId == accountId
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountId, delta);
    }

    if (existing != null && existing.accountId == accountId) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountId, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final entry = EncryptedEntry(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.insertRow(session, entry);
      await StorageQuotaService.incrementUsage(
        session, accountId, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted entry
  Future<bool> deleteEncryptedEntry(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedEntry.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountId, removedSize, 1,
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
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountId == accountId
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountId, delta);
    }

    if (existing != null && existing.accountId == accountId) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountId, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final schedule = EncryptedSchedule(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.insertRow(session, schedule);
      await StorageQuotaService.incrementUsage(
        session, accountId, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted schedule
  Future<bool> deleteEncryptedSchedule(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedSchedule.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountId, removedSize, 1,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Template Aesthetics (non-E2EE, no quota tracking)
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
    final uuidId = UuidValue.fromString(id);

    // DEBUG: Log what the server receives and what accountId it will store
    session.log(
      'DEBUG SyncEndpoint.upsertTemplateAesthetics: '
      'id=$id, accountId=$accountId, templateId=$templateId, '
      'icon=$icon, emoji=$emoji, userIdentifier=${session.authenticated!.userIdentifier}',
      level: LogLevel.info,
    );

    final existing = await TemplateAesthetics.db.findById(session, uuidId);

    // DEBUG: Log existing record state
    session.log(
      'DEBUG SyncEndpoint.upsertTemplateAesthetics: '
      'existing=${existing != null ? "found (accountId=${existing.accountId})" : "null"}',
      level: LogLevel.info,
    );

    final parsedUpdatedAt = _parseDateTime(updatedAt) ?? DateTime.now();

    if (existing != null && existing.accountId == accountId) {
      final updated = existing.copyWith(
        templateId: templateId,
        themeName: themeName,
        icon: icon,
        emoji: emoji,
        paletteJson: paletteJson,
        fontConfigJson: fontConfigJson,
        colorMappingsJson: colorMappingsJson,
        updatedAt: parsedUpdatedAt,
      );
      return await TemplateAesthetics.db.updateRow(session, updated);
    } else {
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
        updatedAt: parsedUpdatedAt,
      );
      return await TemplateAesthetics.db.insertRow(session, aesthetics);
    }
  }

  /// Delete template aesthetics
  Future<bool> deleteTemplateAesthetics(Session session, String id) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing = await TemplateAesthetics.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    await TemplateAesthetics.db.deleteRow(session, existing);
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Encrypted Analysis Scripts
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted analysis script
  Future<EncryptedAnalysisScript> upsertEncryptedAnalysisScript(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisScript.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountId == accountId
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountId, delta);
    }

    if (existing != null && existing.accountId == accountId) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisScript.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountId, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final script = EncryptedAnalysisScript(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisScript.db.insertRow(session, script);
      await StorageQuotaService.incrementUsage(
        session, accountId, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted analysis script
  Future<bool> deleteEncryptedAnalysisScript(
    Session session,
    String id,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisScript.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedAnalysisScript.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountId, removedSize, 1,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Storage Usage
  // ─────────────────────────────────────────────────────────────────────────

  /// Get storage usage for authenticated user
  Future<StorageUsageResponse> getStorageUsage(Session session) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final usage = await StorageQuotaService.getUsage(session, accountId);

    return StorageUsageResponse(
      bytesUsed: usage.bytesUsed,
      rowCount: usage.rowCount,
    );
  }

  /// Safely parse a DateTime string, returning null on invalid input.
  static DateTime? _parseDateTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
