import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/infrastructure/config/app_config.dart';
import '../models/app_operating_mode.dart';
import '../exceptions/app_operating_exceptions.dart';

@lazySingleton
class AppOperatingRepository {
  final AppDatabase _db;
  final AppConfig _config;
  
  AppOperatingRepository(this._db, this._config);
  
  /// Get current operating mode - always from database
  /// Initializes with local mode on first run
  Future<AppOperatingMode> getCurrentMode() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      return settings.mode;
    }, AppOperatingException.new, 'getCurrentMode');
  }
  
  /// Get full settings - always from database
  Future<AppOperatingSetting> getSettings() {
    return tryMethod(() async {
      await _ensureInitialized();
      return await _db.select(_db.appOperatingSettings).getSingle();
    }, AppOperatingException.new, 'getSettings');
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
  
  /// Update operating mode and persist immediately
  Future<void> updateMode(AppOperatingMode mode, {String? selfHostedUrl}) {
    return tryMethod(() async {
      final updated = await _db.update(_db.appOperatingSettings).write(
        AppOperatingSettingsCompanion(
          mode: Value(mode),
          selfHostedUrl: Value(selfHostedUrl),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      if (updated == 0) {
        throw const AppOperatingException('Failed to update operating mode');
      }
    }, AppOperatingException.new, 'updateMode');
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
        throw const AppOperatingException('Failed to update connection status');
      }
    }, AppOperatingException.new, 'updateConnectionStatus');
  }
  
  /// Get whether analytics auto-send is enabled
  Future<bool> getAnalyticsAutoSend() {
    return tryMethod(() async {
      await _ensureInitialized();
      final settings = await _db.select(_db.appOperatingSettings).getSingle();
      return settings.analyticsAutoSend;
    }, AppOperatingException.new, 'getAnalyticsAutoSend');
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
        throw const AppOperatingException('Failed to update analytics auto-send');
      }
    }, AppOperatingException.new, 'updateAnalyticsAutoSend');
  }

  /// Ensure database has initial settings (local mode)
  /// Called on every app startup - idempotent
  Future<void> _ensureInitialized() async {
    final count = await _db.select(_db.appOperatingSettings).get().then((rows) => rows.length);
    
    if (count == 0) {
      // First time - insert local mode as default
      await _db.into(_db.appOperatingSettings).insert(
        AppOperatingSettingsCompanion.insert(
          mode: AppOperatingMode.local,
          isConnected: const Value(false),
        ),
      );
    }
  }
}