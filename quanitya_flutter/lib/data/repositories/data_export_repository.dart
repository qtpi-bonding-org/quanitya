import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../infrastructure/config/debug_log.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';

const _tag = 'data/repositories/data_export_repository';

/// Result of a data export operation.
enum DataExportResult {
  success,
  cancelled,
  failed,
}

/// Thrown when the user cancels the import (e.g. dismisses the file picker).
class ImportCancelledException implements Exception {
  const ImportCancelledException();
}

/// Thrown when the import file is invalid or the import fails.
class ImportFailedException implements Exception {
  final String message;
  const ImportFailedException(this.message);
  @override
  String toString() => 'ImportFailedException: $message';
}

/// Repository for exporting/importing all user data as JSON.
///
/// Uses dynamic table discovery via `db.allTables` so new tables
/// are automatically included without code changes.
@lazySingleton
class DataExportRepository {
  final AppDatabase _db;

  DataExportRepository(this._db);

  /// Returns all exportable table names from the database.
  List<String> getExportableTableNames() {
    return _db.allTables.map((t) => t.actualTableName).toList();
  }

  /// Prepare export data from selected tables.
  ///
  /// Returns an [XFile] ready to share. This is the heavy/async part
  /// (DB queries + JSON encoding) that should run under a loading overlay.
  Future<XFile> prepareExportFile(Set<String> tableNames) async {
    Log.d(_tag, '📤 DataExportRepository: Starting export...');

    final exportData = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'schemaVersion': _db.schemaVersion,
      'format': 'raw_tables',
    };

    for (final tableName in tableNames) {
      final rows = await _db.customSelect('SELECT * FROM $tableName').get();
      exportData[tableName] = rows.map((r) => r.data).toList();
      Log.d(_tag, '📤   $tableName: ${rows.length} rows');
    }

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final filename = 'quanitya_export_$timestamp.json';

    Log.d(_tag, '📤   Prepared file: $filename');

    return XFile.fromData(
      bytes,
      name: filename,
      mimeType: 'application/json',
    );
  }

  /// Share a prepared export file via the system share sheet.
  ///
  /// This opens a platform share sheet which may never return on iOS,
  /// so callers must not hold a loading overlay while awaiting this.
  Future<DataExportResult> shareExportFile(XFile file) async {
    try {
      Log.d(_tag, '📤   Sharing file: ${file.name}');

      final result = await Share.shareXFiles(
        [file],
        subject: 'Quanitya Data Export',
        text: 'Your Quanitya data backup',
      );

      switch (result.status) {
        case ShareResultStatus.success:
          Log.d(_tag, '📤   Export successful');
          return DataExportResult.success;
        case ShareResultStatus.dismissed:
          Log.d(_tag, '📤   Export cancelled by user');
          return DataExportResult.cancelled;
        case ShareResultStatus.unavailable:
          Log.d(_tag, '📤   Share unavailable');
          return DataExportResult.failed;
      }
    } catch (e, stack) {
      Log.d(_tag, '❌ DataExportRepository: Share failed: $e');
      Log.d(_tag, '❌ Stack: $stack');
      rethrow;
    }
  }

  /// Parsed import data held between [parseImportFile] and [importData].
  Map<String, dynamic>? _parsedImport;

  /// Pick a file via FilePicker, parse it, and return the table names found.
  ///
  /// Throws [ImportCancelledException] if the user cancels.
  /// Throws [ImportFailedException] if the file is invalid.
  Future<List<String>> parseImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      throw const ImportCancelledException();
    }

    final file = result.files.single;
    String jsonString;
    if (file.bytes != null) {
      jsonString = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      jsonString = await File(file.path!).readAsString();
    } else {
      throw const ImportFailedException('Could not read selected file.');
    }

    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw const ImportFailedException(
        'Invalid file format. Expected a JSON file.',
      );
    }

    if (parsed['format'] != 'raw_tables') {
      throw const ImportFailedException(
        'Unsupported export format. Please use a file exported from this app.',
      );
    }

    final fileVersion = parsed['schemaVersion'] as int?;
    if (fileVersion != null && fileVersion > _db.schemaVersion) {
      throw const ImportFailedException(
        'This file was exported from a newer version of the app. '
        'Please update the app first.',
      );
    }

    _parsedImport = parsed;

    // Return table names found in the file (excluding metadata keys).
    const metaKeys = {'exportedAt', 'schemaVersion', 'format'};
    final allDbTables = getExportableTableNames().toSet();
    return parsed.keys
        .where((k) => !metaKeys.contains(k) && allDbTables.contains(k))
        .toList();
  }

  /// Import selected tables from the previously parsed file.
  ///
  /// Deletes existing data in each selected table then inserts imported rows.
  /// The entire operation runs in a single transaction for atomicity.
  Future<void> importData(Set<String> tableNames) async {
    final parsed = _parsedImport;
    if (parsed == null) {
      throw const ImportFailedException('No import file loaded.');
    }

    try {
      await _db.transaction(() async {
        for (final tableName in tableNames) {
          final rows = parsed[tableName] as List<dynamic>?;
          if (rows == null || rows.isEmpty) continue;

          // Clear existing data for this table.
          await _db.customStatement('DELETE FROM $tableName');

          for (final row in rows) {
            final map = row as Map<String, dynamic>;
            final columns = map.keys.toList();
            final placeholders = columns.map((_) => '?').join(', ');
            final columnNames = columns.join(', ');
            final values = columns.map((c) => map[c]).toList();

            await _db.customStatement(
              'INSERT OR REPLACE INTO $tableName ($columnNames) VALUES ($placeholders)',
              values,
            );
          }

          Log.d(_tag, '📥   $tableName: ${rows.length} rows imported');
        }
      });

      _parsedImport = null;
      Log.d(_tag, '📥 Import completed successfully');
    } catch (e, stack) {
      Log.d(_tag, '❌ DataExportRepository: Import failed: $e');
      Log.d(_tag, '❌ Stack: $stack');
      if (e is ImportFailedException) rethrow;
      throw ImportFailedException('Import failed: $e');
    }
  }
}
