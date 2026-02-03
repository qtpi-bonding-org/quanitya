import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/app_database.dart';
import '../core/try_operation.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import 'models/api_key_model.dart';
import 'webhook_exception.dart';

/// Repository for API key CRUD operations.
/// 
/// Metadata stored in SQLite (ApiKeys table), actual key values in flutter_secure_storage.
/// Pattern: secureStorageKey = 'apikey_{uuid}' → actual token/key value
@lazySingleton
class ApiKeyRepository {
  final AppDatabase _db;
  final ISecureStorage _secureStorage;
  static const _uuid = Uuid();

  ApiKeyRepository(this._db, this._secureStorage);

  /// Get all API keys (metadata only, not actual values)
  Future<List<ApiKeyModel>> getAll() {
    return tryMethod(
      () async {
        final rows = await _db.select(_db.apiKeys).get();
        return rows.map(_rowToModel).toList();
      },
      ApiKeyException.new,
      'getAll',
    );
  }

  /// Get API key by ID (metadata only)
  Future<ApiKeyModel?> getById(String id) {
    return tryMethod(
      () async {
        final row = await (_db.select(_db.apiKeys)
          ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
        return row != null ? _rowToModel(row) : null;
      },
      ApiKeyException.new,
      'getById',
    );
  }

  /// Get the actual API key value from secure storage
  Future<String?> getKeyValue(String apiKeyId) {
    return tryMethod(
      () async {
        final apiKey = await getById(apiKeyId);
        if (apiKey == null) return null;
        return await _secureStorage.getSecureData(apiKey.secureStorageKey);
      },
      ApiKeyException.new,
      'getKeyValue',
    );
  }

  /// Create a new API key
  /// Returns the created model (without the actual key value)
  Future<ApiKeyModel> create({
    required String name,
    required AuthType authType,
    String? headerName,
    required String keyValue,
  }) {
    return tryMethod(
      () async {
        final id = _uuid.v4();
        final secureStorageKey = 'apikey_$id';
        final now = DateTime.now();

        // Store actual key value in secure storage
        await _secureStorage.storeSecureData(secureStorageKey, keyValue);

        // Store metadata in SQLite
        final companion = ApiKeysCompanion.insert(
          id: id,
          name: name,
          authType: authType.name,
          headerName: Value(headerName),
          secureStorageKey: secureStorageKey,
          updatedAt: now,
        );
        await _db.into(_db.apiKeys).insert(companion);

        return ApiKeyModel(
          id: id,
          name: name,
          authType: authType,
          headerName: headerName,
          secureStorageKey: secureStorageKey,
          updatedAt: now,
        );
      },
      ApiKeyException.new,
      'create',
    );
  }

  /// Update an existing API key
  Future<ApiKeyModel> update({
    required String id,
    String? name,
    AuthType? authType,
    String? headerName,
    String? keyValue,
  }) {
    return tryMethod(
      () async {
        final existing = await getById(id);
        if (existing == null) {
          throw ApiKeyException('API key not found: $id');
        }

        // Update secure storage if key value changed
        if (keyValue != null) {
          await _secureStorage.storeSecureData(existing.secureStorageKey, keyValue);
        }

        // Update metadata in SQLite
        final now = DateTime.now();
        await (_db.update(_db.apiKeys)..where((t) => t.id.equals(id))).write(
          ApiKeysCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            authType: authType != null ? Value(authType.name) : const Value.absent(),
            headerName: Value(headerName ?? existing.headerName),
            updatedAt: Value(now),
          ),
        );

        return ApiKeyModel(
          id: id,
          name: name ?? existing.name,
          authType: authType ?? existing.authType,
          headerName: headerName ?? existing.headerName,
          secureStorageKey: existing.secureStorageKey,
          updatedAt: now,
        );
      },
      ApiKeyException.new,
      'update',
    );
  }

  /// Delete an API key (both metadata and secure storage value)
  Future<void> delete(String id) {
    return tryMethod(
      () async {
        final existing = await getById(id);
        if (existing == null) return;

        // Delete from secure storage first
        await _secureStorage.deleteSecureData(existing.secureStorageKey);

        // Delete from SQLite
        await (_db.delete(_db.apiKeys)..where((t) => t.id.equals(id))).go();
      },
      ApiKeyException.new,
      'delete',
    );
  }

  /// Convert database row to model
  ApiKeyModel _rowToModel(ApiKey row) {
    return ApiKeyModel(
      id: row.id,
      name: row.name,
      authType: AuthType.values.firstWhere(
        (e) => e.name == row.authType,
        orElse: () => AuthType.bearer,
      ),
      headerName: row.headerName,
      secureStorageKey: row.secureStorageKey,
      updatedAt: row.updatedAt,
    );
  }
}
