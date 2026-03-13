import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:injectable/injectable.dart';

import 'powersync_schema.dart';
import '../db/app_database.dart';
import '../../infrastructure/config/dev_config.dart';
import '../../features/app_operating_mode/models/app_operating_mode.dart';

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
  Future<void> connect(Client serverpodClient);
  Future<void> disconnect();
  bool get isConnected;

  /// Connect PowerSync if mode supports sync, disconnect if local mode
  Future<void> handleModeChange(AppOperatingMode mode, Client serverpodClient);
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
  PowerSyncDatabase? _powerSyncDb;
  AppDatabase? _driftDb;
  bool _isConnected = false;

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
    // if (kIsWeb) {
    //   debugPrint('Web: Skipping PowerSync initialization (missing wasm/worker)');
    //   return;
    // }

    try {
      String path;
      if (kIsWeb) {
        // On Web, use a simple filename (stored in IndexedDB/OPFS)
        path = 'quanitya_tracker.db';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        path = join(dir.path, 'quanitya_tracker.db');
      }

      // Initialize PowerSync database with schema and custom logger
      _powerSyncDb = PowerSyncDatabase(
        schema: powerSyncSchema,
        path: path,
        logger: DevConfig.getPowerSyncLogger(),
      );
      await _powerSyncDb!.initialize();

      // Connect Drift to the same database file via SqliteAsyncDriftConnection
      _driftDb = AppDatabase(_powerSyncDb!);
      debugPrint('PowerSync initialized successfully at $path');
    } catch (e, stack) {
      debugPrint('Error initializing PowerSync: $e');
      debugPrintStack(stackTrace: stack);
      rethrow; // Re-throw so service locator knows it failed
    }
  }

  /// Connect to sync with Serverpod backend
  @override
  Future<void> connect(Client serverpodClient) async {
    if (_isConnected) {
      debugPrint('PowerSync: Already connected');
      return;
    }

    try {
      // Disconnect first to avoid "Stream already listened to" on hot restart
      await _powerSyncDb!.disconnect();

      final connector = _ServerpodConnector(serverpodClient);
      await _powerSyncDb!.connect(connector: connector);
      _isConnected = true;
      debugPrint('PowerSync: Connected successfully');
    } catch (e, stack) {
      if (DevConfig.enablePowerSyncConnectionErrors) {
        debugPrint('PowerSync: Connection failed: $e');
        debugPrintStack(stackTrace: stack);
      }
      // Don't rethrow - app can work offline
    }
  }

  /// Disconnect from sync
  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;
    await _powerSyncDb!.disconnect();
    _isConnected = false;
    debugPrint('PowerSync: Disconnected');
  }

  /// Handle app operating mode changes - connect/disconnect PowerSync as needed
  @override
  Future<void> handleModeChange(
    AppOperatingMode mode,
    Client serverpodClient,
  ) async {
    if (mode.supportsSync) {
      // Mode supports sync - ensure PowerSync is connected
      if (!_isConnected) {
        debugPrint('PowerSync: Mode changed to ${mode.name} - connecting...');
        await connect(serverpodClient);
      }
    } else {
      // Local mode - ensure PowerSync is disconnected
      if (_isConnected) {
        debugPrint(
          'PowerSync: Mode changed to ${mode.name} - disconnecting...',
        );
        await disconnect();
      }
    }
  }
}

/// Serverpod backend connector for PowerSync
///
/// Handles:
/// - JWT token fetching from Serverpod for PowerSync auth
/// - Uploading local changes to Serverpod endpoints
class _ServerpodConnector extends PowerSyncBackendConnector {
  final Client _client;
  String? _cachedToken;
  DateTime? _tokenExpiry;

  _ServerpodConnector(this._client);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Check if we have a valid cached token (with 30s buffer)
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now()
            .add(const Duration(seconds: 30))
            .isBefore(_tokenExpiry!)) {
      // For cached tokens, we need to get the endpoint from server again
      // since we don't cache the endpoint (it could change)
      try {
        debugPrint('PowerSync: Using cached token, fetching endpoint...');
        final tokenResponse = await _client.modules.community.powerSync
            .getToken();
        final endpoint = _resolveUrl(tokenResponse.endpoint);
        debugPrint('PowerSync: Got endpoint for cached token: $endpoint');
        return PowerSyncCredentials(
          endpoint: endpoint, // ✅ Use resolved endpoint
          token: _cachedToken!,
        );
      } catch (e) {
        if (DevConfig.enablePowerSyncConnectionErrors) {
          debugPrint('PowerSync: Failed to get endpoint for cached token: $e');
        }
        return null;
      }
    }

    try {
      // Check if client has auth credentials before trying to get token
      final authHeader = await _client.authKeyProvider?.authHeaderValue;
      debugPrint('PowerSync: Auth header available: ${authHeader != null}');
      if (authHeader != null) {
        debugPrint('PowerSync: Auth header length: ${authHeader.length}');
        debugPrint(
          'PowerSync: Auth header prefix: ${authHeader.length > 20 ? authHeader.substring(0, 20) : authHeader}...',
        );
      }

      if (authHeader == null) {
        debugPrint(
          'PowerSync: No auth credentials available yet (user not logged in)',
        );
        return null;
      }

      // Get token from Serverpod PowerSync endpoint
      debugPrint('PowerSync: Calling server getToken endpoint...');
      final tokenResponse = await _client.modules.community.powerSync
          .getToken();
      _cachedToken = tokenResponse.token;
      _tokenExpiry = DateTime.parse(tokenResponse.expiresAt);
      final endpoint = _resolveUrl(tokenResponse.endpoint);

      debugPrint('PowerSync: Got token, expires at $_tokenExpiry');
      debugPrint('PowerSync: Server provided endpoint: $endpoint');

      return PowerSyncCredentials(
        endpoint: endpoint, // ✅ Use resolved endpoint
        token: _cachedToken!,
      );
    } catch (e) {
      if (DevConfig.enablePowerSyncConnectionErrors) {
        debugPrint('PowerSync: Failed to fetch credentials: $e');
      }
      return null;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // Check if client has auth credentials before trying to upload
    final authHeader = await _client.authKeyProvider?.authHeaderValue;
    if (authHeader == null) {
      if (DevConfig.enablePowerSyncLogging) {
        debugPrint('PowerSync: Skipping upload - no auth credentials');
      }
      return;
    }

    // Process all pending CRUD transactions
    int transactionCount = 0;
    while (true) {
      final transaction = await database.getNextCrudTransaction();
      if (transaction == null) {
        if (DevConfig.enablePowerSyncLogging && transactionCount > 0) {
          debugPrint(
            'PowerSync: Completed upload of $transactionCount transactions',
          );
        }
        break;
      }
      transactionCount++;

      if (DevConfig.enablePowerSyncLogging) {
        debugPrint(
          'PowerSync: Uploading transaction #${transaction.transactionId} with ${transaction.crud.length} ops',
        );
      }

      try {
        // Send changes to Serverpod sync endpoints
        for (final op in transaction.crud) {
          await _syncOperation(op);
        }

        await transaction.complete();
        if (DevConfig.enablePowerSyncLogging) {
          debugPrint(
            'PowerSync: Completed transaction #${transaction.transactionId}',
          );
        }
      } catch (e) {
        if (DevConfig.enablePowerSyncConnectionErrors ||
            DevConfig.enablePowerSyncLogging) {
          debugPrint(
            'PowerSync: Upload failed for transaction #${transaction.transactionId}: $e',
          );
        }
        // Don't complete transaction - will retry later
        rethrow;
      }
    }
  }

  Future<void> _syncOperation(CrudEntry op) async {
    final data = op.opData;
    if (DevConfig.enablePowerSyncLogging) {
      debugPrint(
        'PowerSync: Uploading op: ${op.op.name} table: ${op.table} id: ${op.id}',
      );
    }

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
          case 'template_aesthetics':
            await _client.modules.community.sync.upsertTemplateAesthetics(
              op.id,
              (data?['template_id'] as String?) ?? '',
              (data?['theme_name'] as String?) ?? '',
              (data?['icon'] as String?) ?? '',
              (data?['emoji'] as String?) ?? '',
              (data?['palette_json'] as String?) ?? '',
              (data?['font_config_json'] as String?) ?? '',
              (data?['color_mappings_json'] as String?) ?? '',
              (data?['updated_at'] as String?) ??
                  DateTime.now().toIso8601String(),
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
            debugPrint(
              'PowerSync: Notification patch sync disabled (endpoint not available)',
            );
        }
      case UpdateType.delete:
        switch (op.table) {
          case 'encrypted_templates':
            await _client.modules.community.sync.deleteEncryptedTemplate(op.id);
          case 'encrypted_entries':
            await _client.modules.community.sync.deleteEncryptedEntry(op.id);
          case 'encrypted_schedules':
            await _client.modules.community.sync.deleteEncryptedSchedule(op.id);
          case 'template_aesthetics':
            await _client.modules.community.sync.deleteTemplateAesthetics(
              op.id,
            );
          case 'notifications':
            // TODO: Re-enable when notificationSync endpoint is implemented
            // User dismissed notification (soft delete via marked_at)
            // await _client.modules.community.notificationSync.dismiss(op.id);
            debugPrint(
              'PowerSync: Notification delete sync disabled (endpoint not available)',
            );
        }
    }
  }
}
