import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../../infrastructure/crypto/data_encryption_service.dart';

/// Type-safe pairing of local and encrypted tables
///
/// Ensures compile-time safety by linking correct table types
/// and preventing accidental cross-table operations
class TablePair<TLocal, TEncrypted> {
  final TableInfo<Table, TLocal> localTable;
  final TableInfo<Table, TEncrypted> encryptedTable;
  /// The PowerSync table name for raw SQL operations
  final String encryptedTableName;

  const TablePair({
    required this.localTable,
    required this.encryptedTable,
    required this.encryptedTableName,
  });
}

/// Abstract DAO for dual table WRITE operations only.
///
/// Handles atomic writes to both local (plaintext) and encrypted tables.
/// Read operations should query local tables directly via repositories.
///
/// Transaction Strategy:
/// - Uses Drift's db.transaction() for atomicity
/// - Local tables use Drift ORM (insertOnConflictUpdate)
/// - Encrypted tables use db.customStatement() with raw SQL
/// - Both share the same SQLite connection via drift_sqlite_async
///
/// Timestamp Consistency:
/// - A single timestamp is generated BEFORE the transaction
/// - Same timestamp is used for: local table, encrypted table metadata, and encrypted blob
/// - This enables E2EEPuller to skip redundant writes by comparing timestamps
///
/// Why raw SQL for encrypted tables?
/// - PowerSync tables are views, not regular SQLite tables
/// - Drift ORM methods (insertOnConflictUpdate) don't work on views
/// - db.customStatement() works within Drift transactions
abstract class DualDao<TLocal extends DataClass, TEncrypted extends DataClass> {
  final AppDatabase db;
  final IDataEncryption encryption;
  final TablePair<TLocal, TEncrypted> tables;
  final Uuid _uuidGenerator = const Uuid();
  
  /// Whether to wrap operations in transactions.
  /// Set to false when caller manages the transaction externally.
  bool useTransaction;

  DualDao({
    required this.db,
    required this.encryption,
    required this.tables,
    this.useTransaction = true,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Abstract methods - concrete classes MUST implement these
  // ─────────────────────────────────────────────────────────────────────────
  
  Map<String, dynamic> entityToJson(TLocal entity);
  Insertable<TLocal> entityToInsertable(TLocal entity);
  TLocal ensureEntityHasUUID(TLocal entity);
  
  /// Apply the canonical timestamp to the entity.
  /// This ensures local table, encrypted table, and encrypted blob all have the same updatedAt.
  TLocal applyTimestamp(TLocal entity, DateTime timestamp);

  // ─────────────────────────────────────────────────────────────────────────
  // Write Operations (atomic to both tables via Drift transaction)
  // ─────────────────────────────────────────────────────────────────────────

  /// Insert or update (upsert) - inserts if not exists, updates if exists.
  /// 
  /// Uses Drift transaction for atomicity across both:
  /// - Local table (Drift ORM)
  /// - Encrypted table (raw SQL via customStatement)
  /// 
  /// Timestamp consistency: A single timestamp is generated and applied to:
  /// - The entity's updatedAt field (written to local table)
  /// - The encrypted table's updated_at column
  /// - The updatedAt inside the encrypted JSON blob
  /// This enables E2EEPuller to skip redundant writes by comparing timestamps.
  Future<TLocal> upsert(TLocal entity) async {
    debugPrint('🟡 DualDao.upsert called, useTransaction: $useTransaction');
    
    // 0. Generate canonical timestamp BEFORE anything else
    final now = DateTime.now();
    
    // 1. Ensure entity has UUID - generate if missing (before transaction)
    debugPrint('🟡   Step 1: Ensuring UUID...');
    final entityWithUUID = ensureEntityHasUUID(entity);
    
    // 2. Apply canonical timestamp to entity
    debugPrint('🟡   Step 2: Applying timestamp...');
    final entityWithTimestamp = applyTimestamp(entityWithUUID, now);
    final entityId = getEntityId(entityWithTimestamp);

    // 3. Encrypt the data (before transaction - async not allowed inside)
    // The encrypted blob now contains the same `now` timestamp
    debugPrint('🟡   Step 3: Encrypting data...');
    final jsonData = entityToJson(entityWithTimestamp);
    final encryptedBytes = await encryption.encryptData(jsonEncode(jsonData));
    final encryptedData = base64.encode(encryptedBytes);
    debugPrint('🟡   Step 3: Encryption done');

    Future<void> doWrites() async {
      // 4. Upsert to local table (Drift ORM) - uses entity.updatedAt which is `now`
      debugPrint('🟡   Step 4: Upserting to local table...');
      final insertable = entityToInsertable(entityWithTimestamp);
      await db.into(tables.localTable).insertOnConflictUpdate(insertable);
      debugPrint('🟡   Step 4: Local table done');

      // 5. Upsert to encrypted table (raw SQL for PowerSync views)
      // Uses same `now` timestamp for consistency
      debugPrint('🟡   Step 5: Upserting to encrypted table...');
      await db.customStatement(
        '''
        INSERT OR REPLACE INTO ${tables.encryptedTableName} (id, encrypted_data, updated_at)
        VALUES (?, ?, ?)
        ''',
        [entityId, encryptedData, now.toIso8601String()],
      );
      debugPrint('🟡   Step 5: Encrypted table done');
    }

    if (useTransaction) {
      debugPrint('🟡   Using Drift transaction for atomicity');
      await db.transaction(() => doWrites());
    } else {
      debugPrint('🟡   No transaction wrapper (caller manages)');
      await doWrites();
    }

    return entityWithTimestamp;
  }

  /// Bulk upsert multiple entities in a single transaction.
  ///
  /// Strategy:
  /// 1. Pre-process all entities (UUID, timestamp)
  /// 2. Pre-encrypt all entities (async, before transaction)
  /// 3. Single transaction: write all to local + encrypted tables
  ///
  /// This is more efficient than calling upsert() in a loop because:
  /// - All encryption happens upfront (async-safe)
  /// - Single transaction reduces SQLite overhead
  /// - Atomic: all succeed or all fail
  ///
  /// Returns the list of entities with UUIDs and timestamps applied.
  Future<List<TLocal>> bulkUpsert(List<TLocal> entities) async {
    if (entities.isEmpty) return [];

    debugPrint('🟡 DualDao.bulkUpsert called with ${entities.length} entities');

    // 0. Generate canonical timestamp BEFORE anything else
    final now = DateTime.now();

    // 1. Pre-process and pre-encrypt all entities (async allowed here)
    final prepared = <({TLocal entity, String id, String encryptedData})>[];

    for (final entity in entities) {
      // Ensure UUID
      final entityWithUUID = ensureEntityHasUUID(entity);
      // Apply timestamp
      final entityWithTimestamp = applyTimestamp(entityWithUUID, now);
      final entityId = getEntityId(entityWithTimestamp);

      // Encrypt
      final jsonData = entityToJson(entityWithTimestamp);
      final encryptedBytes = await encryption.encryptData(jsonEncode(jsonData));
      final encryptedData = base64.encode(encryptedBytes);

      prepared.add((
        entity: entityWithTimestamp,
        id: entityId,
        encryptedData: encryptedData,
      ));
    }

    debugPrint('🟡   Pre-encryption complete for ${prepared.length} entities');

    // 2. Single transaction for all writes
    Future<void> doWrites() async {
      for (final item in prepared) {
        // Local table (Drift ORM)
        final insertable = entityToInsertable(item.entity);
        await db.into(tables.localTable).insertOnConflictUpdate(insertable);

        // Encrypted table (raw SQL for PowerSync views)
        await db.customStatement(
          '''
          INSERT OR REPLACE INTO ${tables.encryptedTableName} (id, encrypted_data, updated_at)
          VALUES (?, ?, ?)
          ''',
          [item.id, item.encryptedData, now.toIso8601String()],
        );
      }
    }

    if (useTransaction) {
      debugPrint('🟡   Using Drift transaction for bulk atomicity');
      await db.transaction(() => doWrites());
    } else {
      debugPrint('🟡   No transaction wrapper (caller manages)');
      await doWrites();
    }

    debugPrint('🟡   BulkUpsert complete');
    return prepared.map((p) => p.entity).toList();
  }

  /// Delete by ID from both tables.
  Future<void> delete(String id) async {
    Future<void> doDelete() async {
      // Delete from local table (Drift ORM)
      await (db.delete(tables.localTable)
        ..where((t) => (t as dynamic).id.equals(id)))
        .go();
      
      // Delete from encrypted table (raw SQL)
      await db.customStatement(
        'DELETE FROM ${tables.encryptedTableName} WHERE id = ?',
        [id],
      );
    }

    if (useTransaction) {
      await db.transaction(() => doDelete());
    } else {
      await doDelete();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Execute multiple operations in a single atomic transaction.
  /// 
  /// Use this when repository needs to coordinate multiple DAO calls atomically.
  /// The DualDao's internal transaction is disabled when using this.
  /// 
  /// Example:
  /// ```dart
  /// await dualDao.runInTransaction(() async {
  ///   await dualDao.upsert(template);
  ///   await aestheticsDao.upsert(aesthetics);
  /// });
  /// ```
  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    final wasUsingTransaction = useTransaction;
    useTransaction = false; // Disable internal transaction
    try {
      return await db.transaction(() => action());
    } finally {
      useTransaction = wasUsingTransaction; // Restore
    }
  }

  /// Extract entity ID for operations
  String getEntityId(TLocal entity) {
    return (entity as dynamic).id as String;
  }

  /// Generate a new UUID for entities
  String generateUUID() {
    return _uuidGenerator.v4();
  }
}
