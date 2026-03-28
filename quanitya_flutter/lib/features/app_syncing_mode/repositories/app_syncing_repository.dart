import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import '../../../infrastructure/config/debug_log.dart';
import 'package:quanitya_flutter/infrastructure/core/try_operation.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/infrastructure/config/app_config.dart';
import '../models/app_syncing_mode.dart';
import '../exceptions/app_syncing_exceptions.dart';

const _tag = 'features/app_syncing_mode/repositories/app_syncing_repository';

@lazySingleton
class AppSyncingRepository {
  final AppDatabase _db;
  final AppConfig _config;

  bool _initialized = false;

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
      Log.d(_tag, '📋 AppSyncingRepository: getSettings() → mode=${settings.mode.name}');
      return settings;
    }, AppSyncingException.new, 'getSettings');
  }

  /// Watch settings changes - stream from database.
  /// Ensures initialization before subscribing to avoid watchSingle() crash
  /// on empty or duplicate rows.
  Stream<AppOperatingSetting> watchSettings() async* {
    await _ensureInitialized();
    yield* _db.select(_db.appOperatingSettings).watchSingle();
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
      Log.d(_tag, '✅ AppSyncingRepository: Mode updated to ${mode.name} ($updated rows)');
    }, AppSyncingException.new, 'updateMode');
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

  /// Ensure database has exactly one settings row (local mode default).
  /// Called on every app startup - idempotent and race-safe.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final rows = await _db.select(_db.appOperatingSettings).get();

    if (rows.isEmpty) {
      // First time — insert local mode as default
      await _db.into(_db.appOperatingSettings).insert(
        AppOperatingSettingsCompanion.insert(
          mode: AppSyncingMode.local,
        ),
      );
    } else if (rows.length > 1) {
      // Race condition left duplicates — keep first, delete rest
      final idsToDelete = rows.skip(1).map((r) => r.id).toList();
      for (final id in idsToDelete) {
        await (_db.delete(_db.appOperatingSettings)
          ..where((t) => t.id.equals(id)))
          .go();
      }
    }

    _initialized = true;
  }
}

/// Typedef for backward compatibility
