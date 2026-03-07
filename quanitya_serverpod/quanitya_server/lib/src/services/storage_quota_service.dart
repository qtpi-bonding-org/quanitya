import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Per-account storage quota tracking and enforcement.
///
/// Tracks bytes used across all encrypted tables (entries, templates,
/// schedules, analysis pipelines). Gates new inserts when quota exceeded.
/// Updates and deletes are always allowed.
class StorageQuotaService {
  /// Default storage limit: 1 GB
  static const int defaultBytesLimit = 1073741824;

  /// Get or create usage record for account.
  static Future<AccountStorageUsage> getUsage(
    Session session,
    int accountId,
  ) async {
    var usage = await AccountStorageUsage.db.findFirstRow(
      session,
      where: (t) => t.accountId.equals(accountId),
    );
    if (usage == null) {
      usage = await _seedUsage(session, accountId);
    }
    return usage;
  }

  /// Check if account can accept a new write of given size.
  static Future<bool> canWrite(
    Session session,
    int accountId,
    int newBytes,
  ) async {
    final usage = await getUsage(session, accountId);
    return (usage.bytesUsed + newBytes) <= usage.bytesLimit;
  }

  /// Increment after successful insert.
  static Future<void> incrementUsage(
    Session session,
    int accountId,
    int bytes,
    int rows,
  ) async {
    final usage = await getUsage(session, accountId);
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
    int accountId,
    int bytesDelta,
    int rowsDelta,
  ) async {
    final usage = await getUsage(session, accountId);
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
    int accountId,
    int bytes,
    int rows,
  ) async {
    await adjustUsage(session, accountId, -bytes, -rows);
  }

  /// Update the storage limit for an account (e.g. after tier change).
  static Future<void> setLimit(
    Session session,
    int accountId,
    int bytesLimit,
  ) async {
    final usage = await getUsage(session, accountId);
    await AccountStorageUsage.db.updateRow(
      session,
      usage.copyWith(
        bytesLimit: bytesLimit,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Seed usage from actual data (one-time per account).
  static Future<AccountStorageUsage> _seedUsage(
    Session session,
    int accountId,
  ) async {
    final result = await session.db.unsafeQuery(
      '''
      SELECT COALESCE(SUM(LENGTH("encryptedData")), 0)::bigint as bytes_used,
             COUNT(*)::integer as row_count
      FROM (
          SELECT "encryptedData" FROM encrypted_entries WHERE "accountId" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_templates WHERE "accountId" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_schedules WHERE "accountId" = \$1
          UNION ALL
          SELECT "encryptedData" FROM encrypted_analysis_pipelines WHERE "accountId" = \$1
      ) combined
      ''',
      parameters: QueryParameters.positional([accountId]),
    );

    final row = result.first;
    final usage = AccountStorageUsage(
      accountId: accountId,
      bytesUsed: (row[0] as num).toInt(),
      rowCount: (row[1] as num).toInt(),
      bytesLimit: defaultBytesLimit,
      updatedAt: DateTime.now(),
    );

    return await AccountStorageUsage.db.insertRow(session, usage);
  }

  /// Recalculate from scratch (corrects any drift).
  static Future<AccountStorageUsage> recalculate(
    Session session,
    int accountId,
  ) async {
    final existing = await AccountStorageUsage.db.findFirstRow(
      session,
      where: (t) => t.accountId.equals(accountId),
    );
    // Preserve custom limit if set
    final limit = existing?.bytesLimit ?? defaultBytesLimit;
    if (existing != null) {
      await AccountStorageUsage.db.deleteRow(session, existing);
    }
    final reseeded = await _seedUsage(session, accountId);
    if (limit != defaultBytesLimit) {
      await AccountStorageUsage.db.updateRow(
        session,
        reseeded.copyWith(bytesLimit: limit),
      );
    }
    return reseeded;
  }
}
