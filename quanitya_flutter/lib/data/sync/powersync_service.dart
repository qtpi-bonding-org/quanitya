import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:powersync_sqlcipher/powersync.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManagerExtension;
import 'package:injectable/injectable.dart';

import 'powersync_schema.dart';
import '../db/app_database.dart';
import '../../infrastructure/config/dev_config.dart';
import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../infrastructure/security/database_key_service.dart';

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
abstract class IPowerSyncService {
  PowerSyncDatabase get powerSyncDb;
  AppDatabase get driftDb;
  Future<void> initialize();
  Future<void> connect(Client serverpodClient, AppSyncingMode mode);
  Future<void> disconnect();
  bool get isConnected;

  /// The resolved filesystem path to the database file.
  /// Null until initialize() has been called.
  String? get dbPath;

  /// Connect PowerSync if mode supports sync, disconnect if local mode
  Future<void> handleModeChange(AppSyncingMode mode, Client serverpodClient);

  /// Stream of real-time sync status from PowerSync.
  Stream<SyncStatus> get statusStream;

  /// Force disconnect and reconnect PowerSync.
  Future<void> retrySync();
}

/// PowerSync service with integrated Drift database
///
/// Follows PowerSync + Drift integration pattern:
/// - Single SQLite file shared between PowerSync and Drift
/// - PowerSync handles sync to PostgreSQL backend
/// - Drift provides ORM interface for app logic
/// - Automatic change propagation between both APIs
@Singleton(as: IPowerSyncService)
class PowerSyncService implements IPowerSyncService {
  final DatabaseKeyService _keyService;

  PowerSyncService(this._keyService);

  PowerSyncDatabase? _powerSyncDb;
  AppDatabase? _driftDb;
  bool _isConnected = false;
  String? _dbPath;
  AppSyncingMode? _currentMode;
  Client? _currentClient;

  @override
  String? get dbPath => _dbPath;

  @override
  PowerSyncDatabase get powerSyncDb {
    final db = _powerSyncDb;
    if (db == null) {
      throw StateError(
        'PowerSyncService not initialized. Call initialize() before accessing powerSyncDb.',
      );
    }
    return db;
  }

  @override
  AppDatabase get driftDb {
    final db = _driftDb;
    if (db == null) {
      throw StateError(
        'PowerSyncService not initialized. Call initialize() before accessing driftDb.',
      );
    }
    return db;
  }

  @override
  bool get isConnected => _isConnected;

  /// Initialize PowerSync database and connect Drift to it
  @override
  Future<void> initialize() async {
    try {
      String path;
      if (kIsWeb) {
        // On Web, use a simple filename (stored in IndexedDB/OPFS)
        path = 'quanitya_tracker.db';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = join(dir.path, 'quanitya_tracker.db');
      }

      _dbPath = path;

      // Provision the SQLCipher encryption key (device-only, not backed up)
      final keyResult = await _keyService.getOrCreateEncryptedAtRestKey();
      if (!kIsWeb && keyResult.wasCreated && await File(path).exists()) {
        // Keychain was wiped (iOS reinstall) — stale encrypted DB can't be opened.
        // Delete it; PowerSync will create a fresh one. E2EE data restores from sync.
        // (Web: dart:io File is unavailable; web storage is managed by the browser.)
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
      // but this plan intentionally keeps file deletion in PowerSyncService (which
      // already owns the path) and exposes only `deleteEncryptedAtRestKey()` on
      // DatabaseKeyService. This keeps DatabaseKeyService free of filesystem concerns
      // and fully testable without path_provider. The recovery logic is equivalent.
      // `deleteEncryptedAtRestKey()` IS defined as a public method in DatabaseKeyService.
      try {
        await _powerSyncDb!.initialize();
      } catch (e) {
        await _keyService.deleteEncryptedAtRestKey();
        if (!kIsWeb && await File(path).exists()) await File(path).delete();
        final freshKey = (await _keyService.getOrCreateEncryptedAtRestKey()).key;
        final freshFactory = PowerSyncSQLCipherOpenFactory(path: path, key: freshKey);
        _powerSyncDb = PowerSyncDatabase.withFactory(
          freshFactory,
          schema: powerSyncSchema,
          logger: DevConfig.getPowerSyncLogger(),
        );
        await _powerSyncDb!.initialize();
      }

      // Connect Drift to the same database file via SqliteAsyncDriftConnection
      _driftDb = AppDatabase(_powerSyncDb!);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'PowerSync initialization failed: $e');
      rethrow; // Re-throw so service locator knows it failed
    }
  }

  /// Connect to sync with Serverpod backend
  @override
  Future<void> connect(Client serverpodClient, AppSyncingMode mode) async {
    if (_isConnected) return;
    if (_powerSyncDb == null) return;

    try {
      // Disconnect first to avoid "Stream already listened to" on hot restart
      await _powerSyncDb!.disconnect();

      final connector = _ServerpodConnector(serverpodClient, mode);
      await _powerSyncDb!.connect(connector: connector);
      _isConnected = true;
      _currentMode = mode;
      _currentClient = serverpodClient;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: 'PowerSync connection failed: $e');
      // Don't rethrow - app can work offline
    }
  }

  /// Disconnect from sync
  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _powerSyncDb!.disconnect();
    _isConnected = false;
  }

  @override
  Stream<SyncStatus> get statusStream {
    if (_powerSyncDb == null) return const Stream.empty();
    return _powerSyncDb!.statusStream;
  }

  @override
  Future<void> retrySync() async {
    final client = _currentClient;
    final mode = _currentMode;
    if (_powerSyncDb == null || client == null || mode == null) return;
    if (!mode.supportsSync) return;
    await disconnect();
    await connect(client, mode);
  }

  /// Handle app operating mode changes - connect/disconnect PowerSync as needed
  ///
  /// Force reconnects when switching between sync modes (e.g. selfHosted → cloud)
  /// because the connector routes token fetches to different endpoints per mode.
  @override
  Future<void> handleModeChange(
    AppSyncingMode mode,
    Client serverpodClient,
  ) async {
    if (mode.supportsSync) {
      if (_isConnected && _currentMode != mode) {
        // Switching between sync modes — force reconnect with new connector
        await disconnect();
      }
      if (!_isConnected) {
        await connect(serverpodClient, mode);
      }
    } else {
      // Local mode - ensure PowerSync is disconnected
      if (_isConnected) {
        await disconnect();
      }
      _currentMode = mode;
    }
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
    try {
      if (!_client.auth.isAuthenticated) return null;

      final String token;
      final String endpoint;

      switch (_mode) {
        case AppSyncingMode.cloud:
          // Cloud: SyncAccessEndpoint — JWT user_id = 128-char hex public key
          final response = await _client.cloudPowerSync.getToken();
          token = response.token;
          endpoint = _resolveUrl(response.endpoint);
        case AppSyncingMode.selfHosted:
          // Self-hosted: community module — JWT user_id = integer account ID
          final response = await _client.modules.community.powerSync.getToken();
          token = response.token;
          endpoint = _resolveUrl(response.endpoint);
        case AppSyncingMode.local:
          return null; // Should never be called in local mode
      }

      _cachedEndpoint ??= endpoint;

      return PowerSyncCredentials(
        endpoint: _cachedEndpoint!,
        token: token,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Check if client has auth session before trying to upload
    if (!_client.auth.isAuthenticated) return;

    // Process all pending CRUD transactions
    while (true) {
      final transaction = await database.getNextCrudTransaction();
      if (transaction == null) break;

      try {
        // Send changes to Serverpod sync endpoints
        for (final op in transaction.crud) {
          await _syncOperation(op);
        }

        await transaction.complete();
      } catch (e, stack) {
        debugPrintStack(
          stackTrace: stack,
          label: 'PowerSync upload failed for transaction #${transaction.transactionId}: $e',
        );
        // Don't complete transaction - will retry later
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
