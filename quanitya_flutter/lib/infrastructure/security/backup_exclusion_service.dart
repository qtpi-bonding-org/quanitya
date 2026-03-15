import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Excludes the SQLite database file from iOS iCloud backup.
///
/// On iOS: calls the native `excludeFromBackup` method channel registered in
/// AppDelegate.swift. Must be called every app start — iOS can reset the
/// isExcludedFromBackup flag on file operations.
///
/// On Android: backup exclusion is handled statically via XML rules in
/// res/xml/backup_rules.xml and res/xml/data_extraction_rules.xml.
/// No runtime action needed on Android.
///
/// Web: no-op (kIsWeb guard prevents Platform.isIOS access which would throw).
/// macOS: no-op (iCloud backup exclusion does not apply to macOS apps).
@lazySingleton
class BackupExclusionService {
  static const _channel = MethodChannel('com.quanitya.app/backup');

  /// Excludes [dbPath] from iCloud backup on iOS.
  ///
  /// Call this in bootstrap after PowerSync has initialized (DB file exists).
  /// Failures are logged and swallowed — backup exclusion is best-effort.
  Future<void> excludeDatabaseFromBackup(String dbPath) async {
    if (kIsWeb) return; // dart:io Platform is not available on web
    if (!Platform.isIOS) return; // Android uses static XML; macOS is excluded per non-goals

    try {
      await _channel.invokeMethod<bool>('excludeFromBackup', {'path': dbPath});
      debugPrint('BackupExclusionService: excluded $dbPath from iCloud backup');
    } catch (e) {
      // Non-fatal — log and continue. App is usable without this.
      debugPrint('BackupExclusionService: WARNING — failed to exclude DB from backup: $e');
    }
  }
}
