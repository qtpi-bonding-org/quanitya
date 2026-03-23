import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/infrastructure/config/app_config.dart';
import '../models/app_syncing_mode.dart';
import '../exceptions/app_syncing_exceptions.dart';

@lazySingleton
class AppSyncingRepository {
  final AppDatabase _db;
  final AppConfig _config;

  AppSyncingRepository(this._db, this._config);

  /// Get current syncing mode - always from database
  /// Initializes with local mode on first run
  Future<AppSyncingMode> getCurrentMode() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      return settings.mode;
    }, AppSyncingException.new, 'getCurrentMode');
  }

  /// Get full settings - always from database
  Future<AppOperatingSetting> getSettings() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      debugPrint('📋 AppSyncingRepository: getSettings() → mode=${settings.mode.name}, connected=${settings.isConnected}');
      return settings;
    }, AppSyncingException.new, 'getSettings');
  }

  /// Watch settings changes - stream from database
  /// Automatically initializes if needed
  Stream<AppOperatingSetting> watchSettings() {
    return _db.select(_db.appOperatingSettings).watchSingle().asyncMap((setting) async {
      // Ensure initialized before returning any data
      await _ensureInitialized();
      // Re-fetch after initialization to get the actual data
      return await _db.select(_db.appOperatingSettings).getSingle();
    });
  }

  /// Get serverpod URL from environment config (not stored in DB)
  String get serverpodUrl => _config.serverpodUrl;

  /// Get base URL from environment config (not stored in DB)
  /// Extracts base URL from serverpod URL for health checks
  String get baseUrl => _config.baseUrl;

  /// Update syncing mode and persist immediately
  Future<void> updateMode(AppSyncingMode mode, {String? selfHostedUrl}) {
    return tryMethod(() async {
      final updated = await _db.update(_db.appOperatingSettings).write(
        AppOperatingSettingsCompanion(
          mode: Value(mode),
          selfHostedUrl: Value(selfHostedUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (updated == 0) {
        throw const AppSyncingException('Failed to update syncing mode');
      }
      debugPrint('✅ AppSyncingRepository: Mode updated to ${mode.name} ($updated rows)');
    }, AppSyncingException.new, 'updateMode');
  }

  /// Update connection status
  Future<void> updateConnectionStatus(bool isConnected) {
    return tryMethod(() async {
      final updated = await _db.update(_db.appOperatingSettings).write(
        AppOperatingSettingsCompanion(
          isConnected: Value(isConnected),
          lastConnectionTest: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (updated == 0) {
        throw const AppSyncingException('Failed to update connection status');
      }
    }, AppSyncingException.new, 'updateConnectionStatus');
  }

  /// Get whether analytics auto-send is enabled
  Future<bool> getAnalyticsAutoSend() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      return settings.analyticsAutoSend;
    }, AppSyncingException.new, 'getAnalyticsAutoSend');
  }

  /// Update analytics auto-send preference
  Future<void> updateAnalyticsAutoSend(bool enabled) {
    return tryMethod(() async {
      final updated = await _db.update(_db.appOperatingSettings).write(
        AppOperatingSettingsCompanion(
          analyticsAutoSend: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (updated == 0) {
        throw const AppSyncingException('Failed to update analytics auto-send');
      }
    }, AppSyncingException.new, 'updateAnalyticsAutoSend');
  }

  /// Get whether error auto-send is enabled
  Future<bool> getErrorAutoSend() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      return settings.errorAutoSend;
    }, AppSyncingException.new, 'getErrorAutoSend');
  }

  /// Update error auto-send preference
  Future<void> updateErrorAutoSend(bool enabled) {
    return tryMethod(() async {
      final updated = await _db.update(_db.appOperatingSettings).write(
        AppOperatingSettingsCompanion(
          errorAutoSend: Value(enabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (updated == 0) {
        throw const AppSyncingException('Failed to update error auto-send');
      }
    }, AppSyncingException.new, 'updateErrorAutoSend');
  }

  /// Ensure database has initial settings (local mode)
  /// Called on every app startup - idempotent
  Future<void> _ensureInitialized() async {
    final count = await _db.select(_db.appOperatingSettings).get().then((rows) => rows.length);

    if (count == 0) {
      // First time - insert local mode as default
      await _db.into(_db.appOperatingSettings).insert(
        AppOperatingSettingsCompanion.insert(
          mode: AppSyncingMode.local,
          isConnected: const Value(false),
        ),
      );
    }
  }
}

/// Typedef for backward compatibility
typedef AppOperatingRepository = AppSyncingRepository;
