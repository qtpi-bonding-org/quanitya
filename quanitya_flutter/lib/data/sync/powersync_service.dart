import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:powersync_sqlcipher/powersync.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:injectable/injectable.dart';

import 'powersync_schema.dart';
import '../db/app_database.dart';
import '../../infrastructure/config/dev_config.dart';
import '../../features/app_operating_mode/models/app_operating_mode.dart';
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
  Future<void> connect(Client serverpodClient);
  Future<void> disconnect();
  bool get isConnected;

  /// The resolved filesystem path to the database file.
  /// Null until initialize() has been called.
  String? get dbPath;

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
  final DatabaseKeyService _keyService;

  PowerSyncService(this._keyService);

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
    debugPrint('⚡ PowerSync: initialize() called');

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
      debugPrint('⚡ PowerSync: Creating database at $path');
      debugPrint('⚡ PowerSync: Schema tables: ${powerSyncSchema.tables.map((t) => t.name).toList()}');

      // Provision the SQLCipher encryption key (device-only, not backed up)
      final keyResult = await _keyService.getOrCreateEncryptedAtRestKey();
      if (!kIsWeb && keyResult.wasCreated && await File(path).exists()) {
        // Keychain was wiped (iOS reinstall) — stale encrypted DB can't be opened.
        // Delete it; PowerSync will create a fresh one. E2EE data restores from sync.
        // (Web: dart:io File is unavailable; web storage is managed by the browser.)
        debugPrint('⚡ PowerSync: Keychain wipe detected — deleting stale DB at $path');
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
        debugPrint('⚡ PowerSync: DB open failed (bad key?), recovering: $e');
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
      debugPrint('⚡ PowerSync: Database initialized');

      // Connect Drift to the same database file via SqliteAsyncDriftConnection
      _driftDb = AppDatabase(_powerSyncDb!);
      debugPrint('⚡ PowerSync: Drift connected to database');
      debugPrint('⚡ PowerSync: Initialization complete at $path');
    } catch (e, stack) {
      debugPrint('⚡ PowerSync: ERROR during initialization: $e');
      debugPrintStack(stackTrace: stack);
      rethrow; // Re-throw so service locator knows it failed
    }
  }

  /// Connect to sync with Serverpod backend
  @override
  Future<void> connect(Client serverpodClient) async {
    debugPrint('⚡ PowerSync: connect() called');
    debugPrint('⚡ PowerSync: _isConnected=$_isConnected, _powerSyncDb=${_powerSyncDb != null ? "exists" : "null"}');

    if (_isConnected) {
      debugPrint('⚡ PowerSync: Already connected, skipping');
      return;
    }

    if (_powerSyncDb == null) {
      debugPrint('⚡ PowerSync: ERROR - database not initialized, call initialize() first');
      return;
    }

    try {
      // DEBUG: Snapshot table state BEFORE connect
      await _debugLogTableState('BEFORE connect');

      // Disconnect first to avoid "Stream already listened to" on hot restart
      debugPrint('⚡ PowerSync: Disconnecting existing connection (hot restart safety)...');
      await _powerSyncDb!.disconnect();

      // DEBUG: Snapshot table state AFTER disconnect
      await _debugLogTableState('AFTER disconnect');

      debugPrint('⚡ PowerSync: Creating _ServerpodConnector...');
      final connector = _ServerpodConnector(serverpodClient);

      debugPrint('⚡ PowerSync: Calling powerSyncDb.connect()...');
      await _powerSyncDb!.connect(connector: connector);
      _isConnected = true;
      debugPrint('⚡ PowerSync: Connected successfully');

      // DEBUG: Snapshot table state AFTER connect (immediate)
      await _debugLogTableState('AFTER connect (immediate)');

      // DEBUG: Snapshot again after a delay to catch server state application
      Future.delayed(const Duration(seconds: 3), () async {
        await _debugLogTableState('AFTER connect (+3s)');
      });
      Future.delayed(const Duration(seconds: 10), () async {
        await _debugLogTableState('AFTER connect (+10s)');
      });
    } catch (e, stack) {
      debugPrint('⚡ PowerSync: ERROR - Connection failed: $e');
      debugPrintStack(stackTrace: stack);
      // Don't rethrow - app can work offline
    }
  }

  /// Disconnect from sync
  @override
  Future<void> disconnect() async {
    debugPrint('⚡ PowerSync: disconnect() called, _isConnected=$_isConnected');
    if (!_isConnected) {
      debugPrint('⚡ PowerSync: Not connected, skipping disconnect');
      return;
    }
    await _powerSyncDb!.disconnect();
    _isConnected = false;
    debugPrint('⚡ PowerSync: Disconnected');
  }

  /// DEBUG: Log the state of all PowerSync tables
  Future<void> _debugLogTableState(String label) async {
    try {
      final db = _powerSyncDb;
      if (db == null) return;

      debugPrint('🔍 DEBUG [$label] ─────────────────────────────────────');

      // Template aesthetics (the problematic table)
      final aesthetics = await db.getAll('SELECT id, template_id, icon, emoji, updated_at FROM template_aesthetics');
      debugPrint('🔍 DEBUG [$label] template_aesthetics: ${aesthetics.length} rows');
      for (final row in aesthetics) {
        debugPrint('🔍 DEBUG [$label]   id=${row['id']}, template_id=${row['template_id']}, icon=${row['icon']}, emoji=${row['emoji']}');
      }

      // Encrypted templates
      final templates = await db.getAll('SELECT id, LENGTH(encrypted_data) as data_len FROM encrypted_templates');
      debugPrint('🔍 DEBUG [$label] encrypted_templates: ${templates.length} rows');

      // Encrypted entries
      final entries = await db.getAll('SELECT COUNT(*) as cnt FROM encrypted_entries');
      debugPrint('🔍 DEBUG [$label] encrypted_entries: ${entries.first['cnt']} rows');

      // Encrypted analysis scripts
      final scripts = await db.getAll('SELECT COUNT(*) as cnt FROM encrypted_analysis_scripts');
      debugPrint('🔍 DEBUG [$label] encrypted_analysis_scripts: ${scripts.first['cnt']} rows');

      // CRUD queue status
      final pending = await db.getAll('SELECT COUNT(*) as cnt FROM ps_crud');
      debugPrint('🔍 DEBUG [$label] ps_crud (pending uploads): ${pending.first['cnt']} rows');

      debugPrint('🔍 DEBUG [$label] ─────────────────────────────────────');
    } catch (e) {
      debugPrint('🔍 DEBUG [$label] ERROR reading table state: $e');
    }
  }

  /// Handle app operating mode changes - connect/disconnect PowerSync as needed
  @override
  Future<void> handleModeChange(
    AppOperatingMode mode,
    Client serverpodClient,
  ) async {
    debugPrint('⚡ PowerSync: handleModeChange() called with mode=${mode.name}');
    debugPrint('⚡ PowerSync: supportsSync=${mode.supportsSync}, _isConnected=$_isConnected');

    if (mode.supportsSync) {
      // Mode supports sync - ensure PowerSync is connected
      if (!_isConnected) {
        debugPrint('⚡ PowerSync: Mode changed to ${mode.name} - connecting...');
        await connect(serverpodClient);
      } else {
        debugPrint('⚡ PowerSync: Already connected, no action needed');
      }
    } else {
      // Local mode - ensure PowerSync is disconnected
      if (_isConnected) {
        debugPrint('⚡ PowerSync: Mode changed to ${mode.name} - disconnecting...');
        await disconnect();
      } else {
        debugPrint('⚡ PowerSync: Already disconnected, no action needed');
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
  String? _cachedEndpoint;

  _ServerpodConnector(this._client) {
    debugPrint('⚡ PowerSync: _ServerpodConnector created');
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    debugPrint('⚡ PowerSync: fetchCredentials() called');

    try {
      final authHeader = await _client.authKeyProvider?.authHeaderValue;
      if (authHeader == null) {
        debugPrint('⚡ PowerSync: No auth credentials available yet');
        return null;
      }

      // Always fetch a fresh token (cheap single authenticated call).
      // Cache only the endpoint URL since it doesn't change mid-session.
      debugPrint('⚡ PowerSync: Fetching fresh token...');
      final tokenResponse = await _client.modules.community.powerSync
          .getToken();
      _cachedEndpoint ??= _resolveUrl(tokenResponse.endpoint);

      debugPrint('⚡ PowerSync: Got token, expires at ${tokenResponse.expiresAt}');
      debugPrint('⚡ PowerSync: Endpoint: $_cachedEndpoint');

      // DEBUG: Decode JWT to see what user_id is being used
      try {
        final parts = tokenResponse.token.split('.');
        if (parts.length >= 2) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final claims = jsonDecode(payload) as Map<String, dynamic>;
          debugPrint('🔍 DEBUG JWT claims: user_id=${claims['user_id']}, sub=${claims['sub']}');
          debugPrint('🔍 DEBUG JWT user_id type: ${claims['user_id'].runtimeType}');
          debugPrint('🔍 DEBUG JWT user_id length: ${claims['user_id']?.toString().length}');
          debugPrint('🔍 DEBUG JWT: Is user_id a public key hex? ${(claims['user_id']?.toString().length ?? 0) > 60 ? "YES (looks like hex)" : "NO (looks like integer ID — THIS IS THE BUG)"}');
        }
      } catch (e) {
        debugPrint('🔍 DEBUG: Failed to decode JWT: $e');
      }

      return PowerSyncCredentials(
        endpoint: _cachedEndpoint!,
        token: tokenResponse.token,
      );
    } catch (e, stack) {
      debugPrint('⚡ PowerSync: ERROR - Failed to fetch credentials: $e');
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    debugPrint('⚡ PowerSync: uploadData() called');

    // Check if client has auth credentials before trying to upload
    final authHeader = await _client.authKeyProvider?.authHeaderValue;
    if (authHeader == null) {
      debugPrint('⚡ PowerSync: Skipping upload - no auth credentials');
      return;
    }

    // DEBUG: Log table state at start of upload
    debugPrint('🔍 DEBUG uploadData() called — checking table state');

    // Process all pending CRUD transactions
    int transactionCount = 0;
    while (true) {
      final transaction = await database.getNextCrudTransaction();
      if (transaction == null) {
        if (transactionCount > 0) {
          debugPrint('⚡ PowerSync: Completed upload of $transactionCount transactions');
          // DEBUG: Log table state after all uploads
          try {
            final aesthetics = await database.getAll('SELECT id, icon, emoji FROM template_aesthetics');
            debugPrint('🔍 DEBUG post-upload template_aesthetics: ${aesthetics.length} rows');
            for (final row in aesthetics) {
              debugPrint('🔍 DEBUG post-upload   icon=${row['icon']}, emoji=${row['emoji']}');
            }
          } catch (e) {
            debugPrint('🔍 DEBUG post-upload table check failed: $e');
          }
        } else {
          debugPrint('⚡ PowerSync: No pending transactions to upload');
        }
        break;
      }
      transactionCount++;

      debugPrint(
        '⚡ PowerSync: Uploading transaction #${transaction.transactionId} with ${transaction.crud.length} ops',
      );

      try {
        // Send changes to Serverpod sync endpoints
        for (final op in transaction.crud) {
          await _syncOperation(op);
        }

        await transaction.complete();
        debugPrint(
          '⚡ PowerSync: Completed transaction #${transaction.transactionId}',
        );
      } catch (e, stack) {
        debugPrint(
          '⚡ PowerSync: ERROR - Upload failed for transaction #${transaction.transactionId}: $e',
        );
        debugPrintStack(stackTrace: stack);
        // Don't complete transaction - will retry later
        rethrow;
      }
    }
  }

  Future<void> _syncOperation(CrudEntry op) async {
    final data = op.opData;
    debugPrint(
      '⚡ PowerSync: Syncing op: ${op.op.name} table: ${op.table} id: ${op.id}',
    );
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
          default:
            debugPrint('⚡ PowerSync: WARN - Unknown table for PUT: ${op.table}');
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
              '⚡ PowerSync: Notification patch sync disabled (endpoint not available)',
            );
          default:
            debugPrint('⚡ PowerSync: WARN - Unknown table for PATCH: ${op.table}');
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
            debugPrint(
              '⚡ PowerSync: Notification delete sync disabled (endpoint not available)',
            );
          default:
            debugPrint('⚡ PowerSync: WARN - Unknown table for DELETE: ${op.table}');
        }
    }
  }
}
