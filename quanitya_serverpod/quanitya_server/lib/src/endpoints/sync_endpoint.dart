import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/storage_quota_service.dart';

/// Sync endpoint for PowerSync data operations
///
/// Handles CRUD operations for E2EE encrypted data and template aesthetics.
/// All operations require authentication via AnonAccred device key.
/// New inserts are gated by per-account storage quota.
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

    if (existing != null && existing.accountId == accountId) {
      // UPDATE — always allowed
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
      // INSERT — check quota
      if (!await StorageQuotaService.canWrite(
        session, accountId, encryptedData.length,
      )) {
        throw Exception('Storage quota exceeded');
      }
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
      if (!await StorageQuotaService.canWrite(
        session, accountId, encryptedData.length,
      )) {
        throw Exception('Storage quota exceeded');
      }
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
      if (!await StorageQuotaService.canWrite(
        session, accountId, encryptedData.length,
      )) {
        throw Exception('Storage quota exceeded');
      }
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

    final existing = await TemplateAesthetics.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
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
        updatedAt: updatedAt != null
            ? DateTime.parse(updatedAt)
            : DateTime.now(),
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
  // Encrypted Analysis Pipelines
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted analysis pipeline
  Future<EncryptedAnalysisPipeline> upsertEncryptedAnalysisPipeline(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisPipeline.db.findById(session, uuidId);

    if (existing != null && existing.accountId == accountId) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisPipeline.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountId, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      if (!await StorageQuotaService.canWrite(
        session, accountId, encryptedData.length,
      )) {
        throw Exception('Storage quota exceeded');
      }
      final pipeline = EncryptedAnalysisPipeline(
        id: uuidId,
        accountId: accountId,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisPipeline.db.insertRow(session, pipeline);
      await StorageQuotaService.incrementUsage(
        session, accountId, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted analysis pipeline
  Future<bool> deleteEncryptedAnalysisPipeline(
    Session session,
    String id,
  ) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisPipeline.db.findById(session, uuidId);
    if (existing == null || existing.accountId != accountId) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedAnalysisPipeline.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountId, removedSize, 1,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Storage Usage
  // ─────────────────────────────────────────────────────────────────────────

  /// Get storage usage for authenticated user
  Future<Map<String, dynamic>> getStorageUsage(Session session) async {
    final accountId = int.parse(session.authenticated!.userIdentifier);
    final usage = await StorageQuotaService.getUsage(session, accountId);

    return {
      'bytesUsed': usage.bytesUsed,
      'bytesLimit': usage.bytesLimit,
      'rowCount': usage.rowCount,
      'percentUsed': (usage.bytesUsed / usage.bytesLimit * 100).round(),
      'bytesRemaining':
          (usage.bytesLimit - usage.bytesUsed).clamp(0, usage.bytesLimit),
    };
  }
}
