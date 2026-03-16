import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Per-account storage usage tracking.
///
/// Tracks bytes used and row count across all encrypted tables (entries,
/// templates, schedules, analysis scripts).
///
/// Cloud deployments set [storageLimitProvider] at startup to enforce
/// tier-based storage limits. Self-hosted has no limit (provider is null).
class StorageQuotaService {
  /// Optional callback that returns the storage limit in bytes for an account.
  /// Set by the cloud server at startup. Null means no limit (self-hosted).
  static Future<int> Function(Session session, String accountUuid)?
      storageLimitProvider;

  /// Check if writing [additionalBytes] would exceed the account's storage
  /// limit. Throws if over quota. No-op if no [storageLimitProvider] is set
  /// (self-hosted).
  static Future<void> enforceQuota(
    Session session,
    String accountUuid,
    int additionalBytes,
  ) async {
    if (storageLimitProvider == null) return;

    final limitBytes = await storageLimitProvider!(session, accountUuid);
    if (limitBytes <= 0) return; // no active tier

    final usage = await getUsage(session, accountUuid);
    if (usage.bytesUsed + additionalBytes > limitBytes) {
      throw Exception('Storage quota exceeded');
    }
  }

  /// Get or create usage record for account.
  static Future<AccountStorageUsage> getUsage(
    Session session,
    String accountUuid,
  ) async {
    var usage = await AccountStorageUsage.db.findFirstRow(
      session,
      where: (t) => t.accountUuid.equals(accountUuid),
    );
    if (usage == null) {
      usage = await _seedUsage(session, accountUuid);
    }
    return usage;
  }

  /// Increment after successful insert.
  static Future<void> incrementUsage(
    Session session,
    String accountUuid,
    int bytes,
    int rows,
  ) async {
    final usage = await getUsage(session, accountUuid);
    await AccountStorageUsage.db.updateRow(
      session,
      usage.copyWith(
        bytesUsed: usage.bytesUsed + bytes,
        rowCount: usage.rowCount + rows,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Adjust after update (delta can be negative).
  static Future<void> adjustUsage(
    Session session,
    String accountUuid,
    int bytesDelta,
    int rowsDelta,
  ) async {
    final usage = await getUsage(session, accountUuid);
    await AccountStorageUsage.db.updateRow(
      session,
      usage.copyWith(
        bytesUsed: (usage.bytesUsed + bytesDelta).clamp(0, 1 << 62),
        rowCount: (usage.rowCount + rowsDelta).clamp(0, 1 << 62),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Decrement after delete.
  static Future<void> decrementUsage(
    Session session,
    String accountUuid,
    int bytes,
    int rows,
  ) async {
    await adjustUsage(session, accountUuid, -bytes, -rows);
  }

  /// Seed usage from actual data (one-time per account).
  static Future<AccountStorageUsage> _seedUsage(
    Session session,
    String accountUuid,
  ) async {
    final result = await session.db.unsafeQuery(
      '''
      SELECT COALESCE(SUM(LENGTH("encryptedData")), 0)::bigint as bytes_used,
             COUNT(*)::integer as row_count
      FROM (
          SELECT "encryptedData" FROM encrypted_entries WHERE "accountUuid" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_templates WHERE "accountUuid" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_schedules WHERE "accountUuid" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_analysis_scripts WHERE "accountUuid" = \$1
      ) combined
      ''',
      parameters: QueryParameters.positional([accountUuid]),
    );

    final row = result.first;
    final usage = AccountStorageUsage(
      accountUuid: accountUuid,
      bytesUsed: (row[0] as num).toInt(),
      rowCount: (row[1] as num).toInt(),
      updatedAt: DateTime.now(),
    );

    return await AccountStorageUsage.db.insertRow(session, usage);
  }

  /// Recalculate from scratch (corrects any drift).
  static Future<AccountStorageUsage> recalculate(
    Session session,
    String accountUuid,
  ) async {
    final existing = await AccountStorageUsage.db.findFirstRow(
      session,
      where: (t) => t.accountUuid.equals(accountUuid),
    );
    if (existing != null) {
      await AccountStorageUsage.db.deleteRow(session, existing);
    }
    return await _seedUsage(session, accountUuid);
  }
}
