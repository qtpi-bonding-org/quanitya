import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../dao/log_entry_query_dao.dart';
import '../dao/schedule_query_dao.dart';
import '../dao/template_query_dao.dart';

/// Result of a data export operation.
enum DataExportResult {
  success,
  cancelled,
  failed,
}

/// Repository for exporting all user data as JSON.
///
/// Fetches all templates, entries, schedules, and aesthetics,
/// then exports via share sheet for user to save.
@lazySingleton
class DataExportRepository {
  final TemplateQueryDao _templateDao;
  final LogEntryQueryDao _entryDao;
  final ScheduleQueryDao _scheduleDao;

  DataExportRepository(this._templateDao, this._entryDao, this._scheduleDao);

  /// Export all user data as JSON file via share sheet.
  ///
  /// Includes:
  /// - All templates (including archived/hidden)
  /// - All aesthetics
  /// - All log entries
  /// - All schedules
  Future<DataExportResult> exportAllData() async {
    try {
      debugPrint('📤 DataExportRepository: Starting export...');

      // Fetch all data (no filters - include everything)
      final templates = await _templateDao.find();
      final entries = await _entryDao.findAll();
      final schedules = await _scheduleDao.findAll();

      // Fetch aesthetics for each template
      final aestheticsList = <Map<String, dynamic>>[];
      for (final template in templates) {
        final aesthetics = await _templateDao.findAestheticsById(template.id);
        if (aesthetics != null) {
          aestheticsList.add(aesthetics.toJson());
        }
      }

      debugPrint('📤   Templates: ${templates.length}');
      debugPrint('📤   Aesthetics: ${aestheticsList.length}');
      debugPrint('📤   Entries: ${entries.length}');
      debugPrint('📤   Schedules: ${schedules.length}');

      // Build export structure
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'templates': templates.map((t) => t.toJson()).toList(),
        'aesthetics': aestheticsList,
        'entries': entries.map((e) => e.toJson()).toList(),
        'schedules': schedules.map((s) => s.toJson()).toList(),
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final filename = 'quanitya_export_$timestamp.json';

      debugPrint('📤   Sharing file: $filename');

      // Share via native share sheet
      final result = await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: filename,
            mimeType: 'application/json',
          ),
        ],
        subject: 'Quanitya Data Export',
        text: 'Your Quanitya data backup',
      );

      switch (result.status) {
        case ShareResultStatus.success:
          debugPrint('📤   Export successful');
          return DataExportResult.success;
        case ShareResultStatus.dismissed:
          debugPrint('📤   Export cancelled by user');
          return DataExportResult.cancelled;
        case ShareResultStatus.unavailable:
          debugPrint('📤   Share unavailable');
          return DataExportResult.failed;
      }
    } catch (e, stack) {
      debugPrint('❌ DataExportRepository: Export failed: $e');
      debugPrint('❌ Stack: $stack');
      rethrow;
    }
  }
}
