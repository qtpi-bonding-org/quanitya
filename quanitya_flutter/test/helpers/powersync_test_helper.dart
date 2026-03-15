import 'dart:ffi';
import 'dart:io';

import 'package:powersync_sqlcipher/powersync.dart' hide Table;
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite3/sqlite3.dart' as sqlite3_lib;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/sync/powersync_schema.dart';

/// Custom open factory that loads Homebrew's SQLite (with extension loading)
/// and the PowerSync extension from the project root.
///
/// This runs inside the SQLite isolate, which is why we can't just call
/// `sqlite_open.open.overrideFor()` from the main isolate.
class _TestPowerSyncOpenFactory extends PowerSyncOpenFactory {
  final String _extensionPath;

  _TestPowerSyncOpenFactory({
    required super.path,
    required String extensionPath,
  }) : _extensionPath = extensionPath;

  void _overrideSqliteForIsolate() {
    sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.macOS, () {
      const paths = [
        '/usr/local/opt/sqlite/lib/libsqlite3.dylib', // Intel
        '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib', // ARM
      ];
      for (final path in paths) {
        if (File(path).existsSync()) {
          return DynamicLibrary.open(path);
        }
      }
      return DynamicLibrary.open('libsqlite3.dylib');
    });

    sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.linux, () {
      return DynamicLibrary.open('libsqlite3.so.0');
    });
  }

  @override
  void enableExtension() {
    sqlite3_lib.sqlite3.ensureExtensionLoaded(
      sqlite3_lib.SqliteExtension.inLibrary(
        DynamicLibrary.open(_extensionPath),
        'sqlite3_powersync_init',
      ),
    );
  }

  @override
  open(SqliteOpenOptions options) {
    _overrideSqliteForIsolate();
    return super.open(options);
  }
}

/// Resolves the absolute path to libpowersync.dylib / .so / .dll
/// in the project root directory.
///
/// The native library must be present. Run `scripts/setup_powersync_tests.sh`
/// to download it automatically.
String _resolveExtensionPath() {
  var dir = Directory.current;
  for (var i = 0; i < 5; i++) {
    for (final name in [
      'libpowersync.dylib',
      'libpowersync.so',
      'powersync.dll',
    ]) {
      final candidate = File('${dir.path}/$name');
      if (candidate.existsSync()) return candidate.absolute.path;
    }
    dir = dir.parent;
  }
  throw StateError(
    'Could not find native PowerSync library. '
    'Run: scripts/setup_powersync_tests.sh',
  );
}

String? _extensionPath;

/// Returns the resolved extension path (cached after first call).
String get extensionPath => _extensionPath ??= _resolveExtensionPath();

/// Create a PowerSyncDatabase backed by a temp-file SQLite database
/// with the PowerSync extension loaded via a custom factory.
///
/// The caller must call `db.close()` in tearDown.
Future<PowerSyncDatabase> createTestPowerSyncDatabase({
  Schema? schema,
}) async {
  final tmpDir = await Directory.systemTemp.createTemp('powersync_test_');
  final dbPath = '${tmpDir.path}/test.db';

  final factory = _TestPowerSyncOpenFactory(
    path: dbPath,
    extensionPath: extensionPath,
  );

  final db = PowerSyncDatabase.withFactory(
    factory,
    schema: schema ?? powerSyncSchema,
  );
  await db.initialize();
  return db;
}

/// Create a Drift AppDatabase backed by PowerSync for integration testing.
///
/// Returns both the PowerSyncDatabase (for sync-layer tests) and the
/// AppDatabase (for Drift DAO/repository tests). Close both in tearDown.
Future<({PowerSyncDatabase powerSync, AppDatabase drift})>
    createTestPowerSyncWithDrift({Schema? schema}) async {
  final psDb = await createTestPowerSyncDatabase(schema: schema);
  final driftDb = AppDatabase(psDb);
  return (powerSync: psDb, drift: driftDb);
}
