import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:powersync_sqlcipher/powersync.dart';

import '../../infrastructure/config/debug_log.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManagerExtension;
import 'package:injectable/injectable.dart';

import 'powersync_schema.dart';
import '../db/app_database.dart';
import '../../infrastructure/config/dev_config.dart';
import '../../infrastructure/core/try_operation.dart';
import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../infrastructure/security/database_key_service.dart';

const _tag = 'data/sync/powersync_service';

/// Exception thrown when PowerSync operations fail.
class PowerSyncException implements Exception {
  final String message;
  final Object? cause;

  const PowerSyncException(this.message, [this.cause]);

  @override
  String toString() =>
      'PowerSyncException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Resolve localhost for Android emulator loopback
String _resolveUrl(String url) {
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      url.contains('localhost')) {
    return url.replaceAll('localhost', '10.0.2.2');
  }
  return url;
}

/// Interface for PowerSync service
abstract class IPowerSyncRepository {
  PowerSyncDatabase get powerSyncDb;
  AppDatabase get driftDb;
  Future<void> initialize();
  Future<void> connect(Client serverpodClient, AppSyncingMode mode);
  Future<void> disconnect();
  bool get isConnected;

  /// The resolved filesystem path to the database file.
  /// Null until initialize() has been called.
  String? get dbPath;

  /// Stream of real-time sync status from PowerSync.
  Stream<SyncStatus> get statusStream;

}

/// PowerSync service with integrated Drift database
///
/// Follows PowerSync + Drift integration pattern:
/// - Single SQLite file shared between PowerSync and Drift
/// - PowerSync handles sync to PostgreSQL backend
/// - Drift provides ORM interface for app logic
/// - Automatic change propagation between both APIs
@Singleton(as: IPowerSyncRepository)
class PowerSyncRepository implements IPowerSyncRepository {
  final DatabaseKeyService _keyService;

  PowerSyncRepository(this._keyService);

  PowerSyncDatabase? _powerSyncDb;
  AppDatabase? _driftDb;
  bool _isConnected = false;
  String? _dbPath;


  @override
  String? get dbPath => _dbPath;

  @override
  PowerSyncDatabase get powerSyncDb {
    final db = _powerSyncDb;
    if (db == null) {
      throw StateError(
        'PowerSyncRepository not initialized. Call initialize() before accessing powerSyncDb.',
      );
    }
    return db;
  }

  @override
  AppDatabase get driftDb {
    final db = _driftDb;
    if (db == null) {
      throw StateError(
        'PowerSyncRepository not initialized. Call initialize() before accessing driftDb.',
      );
    }
    return db;
  }

  @override
  bool get isConnected => _isConnected;

  /// Initialize PowerSync database and connect Drift to it
  @override
  Future<void> initialize() {
    return tryMethod(() async {
      String path;
      if (kIsWeb) {
        path = 'quanitya_tracker.db';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = join(dir.path, 'quanitya_tracker.db');
      }

      _dbPath = path;
      final dbExists = !kIsWeb && await File(path).exists();
      Log.d(_tag, '🗄️ PowerSync.initialize: path=$path, dbExists=$dbExists');

      // Provision the SQLCipher encryption key (device-only, not backed up)
      final keyResult = await _keyService.getOrCreateEncryptedAtRestKey();
      Log.d(_tag, '🗄️ PowerSync.initialize: cipherKey wasCreated=${keyResult.wasCreated}');
      if (!kIsWeb && keyResult.wasCreated && await File(path).exists()) {
        Log.d(_tag, '🗄️ PowerSync.initialize: DELETING stale DB file (cipher key was recreated)');
        await File(path).delete();
      }

      final factory = PowerSyncSQLCipherOpenFactory(
        path: path,
        key: keyResult.key,
      );
      _powerSyncDb = PowerSyncDatabase.withFactory(
        factory,
        schema: powerSyncSchema,
        logger: DevConfig.getPowerSyncLogger(),
      );

      // Open DB; catch SQLCipher failures (wrong key) and recover once.
      // Note: the spec names this `deleteKeyAndStaleDatabase()` on DatabaseKeyService,
      // but this plan intentionally keeps file deletion in PowerSyncRepository (which
      // already owns the path) and exposes only `deleteEncryptedAtRestKey()` on
      // DatabaseKeyService. This keeps DatabaseKeyService free of filesystem concerns
      // and fully testable without path_provider. The recovery logic is equivalent.
      // `deleteEncryptedAtRestKey()` IS defined as a public method in DatabaseKeyService.
      try {
        final db0 = _powerSyncDb;
        if (db0 == null) throw PowerSyncException('PowerSync not initialized');
        await db0.initialize();
      } catch (e) {
        if (e is PowerSyncException) rethrow;
        await _keyService.deleteEncryptedAtRestKey();
        if (!kIsWeb && await File(path).exists()) await File(path).delete();
        final freshKey = (await _keyService.getOrCreateEncryptedAtRestKey()).key;
        final freshFactory = PowerSyncSQLCipherOpenFactory(path: path, key: freshKey);
        _powerSyncDb = PowerSyncDatabase.withFactory(
          freshFactory,
          schema: powerSyncSchema,
          logger: DevConfig.getPowerSyncLogger(),
        );
        final db1 = _powerSyncDb;
        if (db1 == null) throw PowerSyncException('PowerSync not initialized');
        await db1.initialize();
      }

      // Connect Drift to the same database file via SqliteAsyncDriftConnection
      final dbForDrift = _powerSyncDb;
      if (dbForDrift == null) throw PowerSyncException('PowerSync not initialized');
      _driftDb = AppDatabase(dbForDrift);
    }, PowerSyncException.new, 'initialize');
  }

  /// Connect to sync with Serverpod backend
  @override
  Future<void> connect(Client serverpodClient, AppSyncingMode mode) {
    return tryMethod(() async {
      Log.d(_tag, '🔌 PowerSync.connect: mode=$mode, _isConnected=$_isConnected');
      if (_isConnected) {
        Log.d(_tag, '🔌 PowerSync.connect: already connected, skipping');
        return;
      }
      final db = _powerSyncDb;
      if (db == null) throw PowerSyncException('PowerSync not initialized — call initialize() first');

      // Check ps_crud count before connecting
      final crudCount = await db.execute('SELECT count(*) as cnt FROM ps_crud');
      Log.d(_tag, '🔌 PowerSync.connect: ps_crud count BEFORE connect = ${crudCount.first['cnt']}');

      // Disconnect first to avoid "Stream already listened to" on hot restart
      await db.disconnect();

      final connector = _ServerpodConnector(
        serverpodClient,
        mode,
      );
      await db.connect(connector: connector);
      _isConnected = true;
      Log.d(_tag, '🔌 PowerSync.connect: connected successfully');
    }, PowerSyncException.new, 'connect');
  }

  /// Disconnect from sync
  @override
  Future<void> disconnect() {
    return tryMethod(() async {
      Log.d(_tag, '🔌 PowerSync.disconnect: _isConnected=$_isConnected, db=${_powerSyncDb != null}');
      if (!_isConnected) {
        Log.d(_tag, '🔌 PowerSync.disconnect: not connected, returning');
        return;
      }
      final db = _powerSyncDb;
      if (db == null) throw PowerSyncException('PowerSync not initialized — call initialize() first');
      Log.d(_tag, '🔌 PowerSync.disconnect: calling db.disconnect()...');
      await db.disconnect();
      Log.d(_tag, '🔌 PowerSync.disconnect: db.disconnect() done');
      _isConnected = false;
    }, PowerSyncException.new, 'disconnect');
  }

  @override
  Stream<SyncStatus> get statusStream {
    final db = _powerSyncDb;
    if (db == null) return const Stream.empty();
    return db.statusStream;
  }

}

/// Serverpod backend connector for PowerSync
///
/// Handles:
/// - JWT token fetching from Serverpod for PowerSync auth (routed by mode)
/// - Uploading local changes to Serverpod endpoints
class _ServerpodConnector extends PowerSyncBackendConnector {
  final Client _client;
  final AppSyncingMode _mode;
  String? _cachedEndpoint;

  _ServerpodConnector(this._client, this._mode);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    Log.d(_tag, '🔑 PowerSync.fetchCredentials: isAuthenticated=${_client.auth.isAuthenticated}, mode=$_mode');
    if (!_client.auth.isAuthenticated) {
      Log.d(_tag, '🔑 PowerSync.fetchCredentials: not authenticated, returning null');
      return null;
    }

    final String token;
    final String endpoint;

    switch (_mode) {
      case AppSyncingMode.cloud:
        final response = await _client.cloudPowerSync.getToken();
        token = response.token;
        endpoint = _resolveUrl(response.endpoint);
        Log.d(_tag, '🔑 PowerSync.fetchCredentials: got cloud token, endpoint=$endpoint');
      case AppSyncingMode.selfHosted:
        final response = await _client.modules.community.powerSync.getToken();
        token = response.token;
        endpoint = _resolveUrl(response.endpoint);
        Log.d(_tag, '🔑 PowerSync.fetchCredentials: got self-hosted token, endpoint=$endpoint');
      case AppSyncingMode.local:
        Log.d(_tag, '🔑 PowerSync.fetchCredentials: local mode, returning null');
        return null;
    }

    _cachedEndpoint ??= endpoint;
    final resolvedEndpoint = _cachedEndpoint ?? endpoint;

    return PowerSyncCredentials(
      endpoint: resolvedEndpoint,
      token: token,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    Log.d(_tag, '📤 PowerSync.uploadData called, isAuthenticated=${_client.auth.isAuthenticated}');
    if (!_client.auth.isAuthenticated) {
      Log.d(_tag, '📤 PowerSync.uploadData: not authenticated, skipping');
      return;
    }

    // Process all pending CRUD transactions
    var txCount = 0;
    while (true) {
      final transaction = await database.getNextCrudTransaction();
      if (transaction == null) {
        Log.d(_tag, '📤 PowerSync.uploadData: done, processed $txCount transactions');
        break;
      }
      txCount++;

      try {
        Log.d(_tag, '📤 PowerSync.uploadData: transaction #${transaction.transactionId} with ${transaction.crud.length} ops');
        for (final op in transaction.crud) {
          Log.d(_tag, '📤   ${op.op.name} ${op.table} id=${op.id}');
          await _syncOperation(op);
        }

        await transaction.complete();
        Log.d(_tag, '📤   transaction #${transaction.transactionId} complete');
      } catch (e, stack) {
        Log.d(_tag, '📤   transaction #${transaction.transactionId} FAILED: $e');
        debugPrintStack(
          stackTrace: stack,
          label: 'PowerSync upload failed for transaction #${transaction.transactionId}: $e',
        );
        rethrow;
      }
    }
  }

  Future<void> _syncOperation(CrudEntry op) async {
    final data = op.opData;
    switch (op.op) {
      case UpdateType.put:
        switch (op.table) {
          case 'encrypted_templates':
            await _client.modules.community.sync.upsertEncryptedTemplate(
              op.id,
              (data?['encrypted_data'] as String?) ?? '',
            );
          case 'encrypted_entries':
            await _client.modules.community.sync.upsertEncryptedEntry(
              op.id,
              (data?['encrypted_data'] as String?) ?? '',
            );
          case 'encrypted_schedules':
            await _client.modules.community.sync.upsertEncryptedSchedule(
              op.id,
              (data?['encrypted_data'] as String?) ?? '',
            );
          case 'encrypted_analysis_scripts':
            await _client.modules.community.sync
                .upsertEncryptedAnalysisScript(
              op.id,
              (data?['encrypted_data'] as String?) ?? '',
            );
          case 'encrypted_template_aesthetics':
            await _client.modules.community.sync
                .upsertEncryptedTemplateAesthetics(
              op.id,
              (data?['encrypted_data'] as String?) ?? '',
            );
        }
      case UpdateType.patch:
        switch (op.table) {
          case 'notifications':
            // TODO: Re-enable when notificationSync endpoint is implemented
            // User marked notification as received
            // await _client.modules.community.notificationSync.markAsReceived(
            //   op.id,
            //   (data?['marked_at'] as String?) ?? DateTime.now().toIso8601String(),
            // );
            break;
        }
      case UpdateType.delete:
        switch (op.table) {
          case 'encrypted_templates':
            await _client.modules.community.sync.deleteEncryptedTemplate(op.id);
          case 'encrypted_entries':
            await _client.modules.community.sync.deleteEncryptedEntry(op.id);
          case 'encrypted_schedules':
            await _client.modules.community.sync.deleteEncryptedSchedule(op.id);
          case 'encrypted_analysis_scripts':
            await _client.modules.community.sync
                .deleteEncryptedAnalysisScript(op.id);
          case 'encrypted_template_aesthetics':
            await _client.modules.community.sync
                .deleteEncryptedTemplateAesthetics(op.id);
          case 'notifications':
            // TODO: Re-enable when notificationSync endpoint is implemented
            // User dismissed notification (soft delete via marked_at)
            // await _client.modules.community.notificationSync.dismiss(op.id);
            break;
        }
    }
  }
}
