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
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplate.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountUuid == accountUuid
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountUuid, delta);
    }

    if (existing != null && existing.accountUuid == accountUuid) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountUuid, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final template = EncryptedTemplate(
        id: uuidId,
        accountUuid: accountUuid,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplate.db.insertRow(session, template);
      await StorageQuotaService.incrementUsage(
        session, accountUuid, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted template
  Future<bool> deleteEncryptedTemplate(Session session, String id) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplate.db.findById(session, uuidId);
    if (existing == null || existing.accountUuid != accountUuid) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedTemplate.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountUuid, removedSize, 1,
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
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountUuid == accountUuid
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountUuid, delta);
    }

    if (existing != null && existing.accountUuid == accountUuid) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountUuid, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final entry = EncryptedEntry(
        id: uuidId,
        accountUuid: accountUuid,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedEntry.db.insertRow(session, entry);
      await StorageQuotaService.incrementUsage(
        session, accountUuid, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted entry
  Future<bool> deleteEncryptedEntry(Session session, String id) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedEntry.db.findById(session, uuidId);
    if (existing == null || existing.accountUuid != accountUuid) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedEntry.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountUuid, removedSize, 1,
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
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountUuid == accountUuid
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountUuid, delta);
    }

    if (existing != null && existing.accountUuid == accountUuid) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountUuid, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final schedule = EncryptedSchedule(
        id: uuidId,
        accountUuid: accountUuid,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedSchedule.db.insertRow(session, schedule);
      await StorageQuotaService.incrementUsage(
        session, accountUuid, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted schedule
  Future<bool> deleteEncryptedSchedule(Session session, String id) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedSchedule.db.findById(session, uuidId);
    if (existing == null || existing.accountUuid != accountUuid) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedSchedule.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountUuid, removedSize, 1,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Encrypted Template Aesthetics (E2EE, with quota tracking)
  // ─────────────────────────────────────────────────────────────────────────

  /// Upsert encrypted template aesthetics
  Future<EncryptedTemplateAesthetics> upsertEncryptedTemplateAesthetics(
    Session session,
    String id,
    String encryptedData,
  ) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplateAesthetics.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountUuid == accountUuid
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountUuid, delta);
    }

    if (existing != null && existing.accountUuid == accountUuid) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplateAesthetics.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountUuid, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final aesthetics = EncryptedTemplateAesthetics(
        id: uuidId,
        accountUuid: accountUuid,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result = await EncryptedTemplateAesthetics.db.insertRow(session, aesthetics);
      await StorageQuotaService.incrementUsage(
        session, accountUuid, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted template aesthetics
  Future<bool> deleteEncryptedTemplateAesthetics(
    Session session,
    String id,
  ) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing = await EncryptedTemplateAesthetics.db.findById(session, uuidId);
    if (existing == null || existing.accountUuid != accountUuid) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedTemplateAesthetics.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountUuid, removedSize, 1,
    );
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
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisScript.db.findById(session, uuidId);
    final delta = encryptedData.length -
        (existing != null && existing.accountUuid == accountUuid
            ? existing.encryptedData.length
            : 0);
    if (delta > 0) {
      await StorageQuotaService.enforceQuota(session, accountUuid, delta);
    }

    if (existing != null && existing.accountUuid == accountUuid) {
      final oldSize = existing.encryptedData.length;
      final updated = existing.copyWith(
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisScript.db.updateRow(session, updated);
      await StorageQuotaService.adjustUsage(
        session, accountUuid, encryptedData.length - oldSize, 0,
      );
      return result;
    } else {
      final script = EncryptedAnalysisScript(
        id: uuidId,
        accountUuid: accountUuid,
        encryptedData: encryptedData,
        updatedAt: DateTime.now(),
      );
      final result =
          await EncryptedAnalysisScript.db.insertRow(session, script);
      await StorageQuotaService.incrementUsage(
        session, accountUuid, encryptedData.length, 1,
      );
      return result;
    }
  }

  /// Delete encrypted analysis script
  Future<bool> deleteEncryptedAnalysisScript(
    Session session,
    String id,
  ) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final uuidId = UuidValue.fromString(id);

    final existing =
        await EncryptedAnalysisScript.db.findById(session, uuidId);
    if (existing == null || existing.accountUuid != accountUuid) {
      return false;
    }

    final removedSize = existing.encryptedData.length;
    await EncryptedAnalysisScript.db.deleteRow(session, existing);
    await StorageQuotaService.decrementUsage(
      session, accountUuid, removedSize, 1,
    );
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Storage Usage
  // ─────────────────────────────────────────────────────────────────────────

  /// Get storage usage for authenticated user
  Future<StorageUsageResponse> getStorageUsage(Session session) async {
    final accountUuid = session.authenticated!.userIdentifier;
    final usage = await StorageQuotaService.getUsage(session, accountUuid);

    return StorageUsageResponse(
      bytesUsed: usage.bytesUsed,
      rowCount: usage.rowCount,
    );
  }

}
