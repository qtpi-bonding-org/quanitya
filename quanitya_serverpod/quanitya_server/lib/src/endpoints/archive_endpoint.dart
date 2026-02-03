import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/r2_storage_service.dart';
import '../services/archival_service.dart';

/// Archive retrieval endpoint for accessing historical data
/// 
/// Provides API access to archived data stored in R2.
/// All operations require authentication and validate user ownership.
class ArchiveEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Get archived data for a specific month
  /// 
  /// [year] - Year (e.g., 2024)
  /// [month] - Month (1-12)
  /// 
  /// Returns [ArchivedMonth] containing all archived data for that month
  Future<ArchivedMonth?> getArchivedMonth(
    Session session,
    int year,
    int month,
  ) async {
    final userId = int.parse(session.authenticated!.userIdentifier);
    final r2Storage = R2StorageService.fromEnvironment();
    
    if (month < 1 || month > 12) {
      throw Exception('Invalid month: $month. Must be between 1 and 12.');
    }
    
    final key = 'archives/$userId/$year/${month.toString().padLeft(2, '0')}.json.gz';
    
    try {
      // Download compressed archive from R2
      final compressed = await r2Storage.downloadArchive(key);
      
      // Decompress and parse JSON
      final jsonBytes = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(jsonBytes);
      final archiveData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Convert to ArchivedMonth object
      return _parseArchivedMonth(archiveData);
      
    } catch (e) {
      session.log('Failed to retrieve archive $key: $e');
      return null;
    }
  }

  /// Get archived data for a date range (multiple months)
  /// 
  /// [startYear] - Start year
  /// [startMonth] - Start month (1-12)
  /// [endYear] - End year
  /// [endMonth] - End month (1-12)
  /// 
  /// Returns list of [ArchivedMonth] objects for the date range
  Future<List<ArchivedMonth>> getArchivedDateRange(
    Session session,
    int startYear,
    int startMonth,
    int endYear,
    int endMonth,
  ) async {
    final results = <ArchivedMonth>[];
    
    // Validate input
    if (startMonth < 1 || startMonth > 12 || endMonth < 1 || endMonth > 12) {
      throw Exception('Invalid month values. Must be between 1 and 12.');
    }
    
    final startDate = DateTime(startYear, startMonth, 1);
    final endDate = DateTime(endYear, endMonth, 1);
    
    if (startDate.isAfter(endDate)) {
      throw Exception('Start date must be before or equal to end date.');
    }
    
    // Iterate through each month in the range
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final archivedMonth = await getArchivedMonth(session, currentDate.year, currentDate.month);
      if (archivedMonth != null) {
        results.add(archivedMonth);
      }
      
      // Move to next month
      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
    }
    
    return results;
  }

  /// Get metadata about available archived months for the authenticated user
  /// 
  /// Returns [ArchiveMetadata] with list of available months and statistics
  Future<ArchiveMetadata> getArchiveMetadata(Session session) async {
    final userId = int.parse(session.authenticated!.userIdentifier);
    final r2Storage = R2StorageService.fromEnvironment();
    
    try {
      // List all archives for this user
      final archiveKeys = await r2Storage.listUserArchives(userId);
      
      final availableMonths = <ArchiveMonthInfo>[];
      
      // Parse each archive key to extract month info
      for (final key in archiveKeys) {
        final monthInfo = _parseArchiveKey(key);
        if (monthInfo != null) {
          // Get metadata without downloading full archive
          final metadata = await r2Storage.getArchiveMetadata(key);
          
          availableMonths.add(ArchiveMonthInfo(
            year: monthInfo.year,
            month: monthInfo.month,
            archiveKey: key,
            uploadedAt: metadata?['uploaded-at'],
          ));
        }
      }
      
      // Sort by date (newest first)
      availableMonths.sort((a, b) {
        final dateA = DateTime(a.year, a.month);
        final dateB = DateTime(b.year, b.month);
        return dateB.compareTo(dateA);
      });
      
      return ArchiveMetadata(
        userId: userId,
        availableMonths: availableMonths,
        totalArchives: availableMonths.length,
        oldestArchive: availableMonths.isNotEmpty 
            ? DateTime(availableMonths.last.year, availableMonths.last.month)
            : null,
        newestArchive: availableMonths.isNotEmpty 
            ? DateTime(availableMonths.first.year, availableMonths.first.month)
            : null,
      );
      
    } catch (e) {
      session.log('Failed to get archive metadata for user $userId: $e');
      throw Exception('Failed to retrieve archive metadata: $e');
    }
  }

  /// Search archived entries by date range (lightweight metadata only)
  /// 
  /// [startDate] - Start date for search
  /// [endDate] - End date for search
  /// 
  /// Returns list of [ArchiveSearchResult] with entry metadata (no encrypted data)
  Future<List<ArchiveSearchResult>> searchArchivedEntries(
    Session session,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = int.parse(session.authenticated!.userIdentifier);
    final r2Storage = R2StorageService.fromEnvironment();
    final results = <ArchiveSearchResult>[];
    
    // Get archives that might contain data in the date range
    final startMonth = DateTime(startDate.year, startDate.month, 1);
    final endMonth = DateTime(endDate.year, endDate.month, 1);
    
    var currentMonth = startMonth;
    while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
      final key = 'archives/$userId/${currentMonth.year}/${currentMonth.month.toString().padLeft(2, '0')}.json.gz';
      
      try {
        // Check if archive exists
        final exists = await r2Storage.verifyArchiveExists(key);
        if (exists) {
          results.add(ArchiveSearchResult(
            year: currentMonth.year,
            month: currentMonth.month,
            archiveKey: key,
            hasData: true,
          ));
        }
      } catch (e) {
        session.log('Error checking archive $key: $e');
      }
      
      // Move to next month
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
    
    return results;
  }

  /// Manual archival trigger for testing and maintenance
  /// 
  /// Triggers the monthly archival process manually.
  /// Useful for testing and one-off archival operations.
  Future<String> runManualArchival(Session session) async {
    try {
      session.log('Manual archival triggered by user ${session.authenticated!.userIdentifier}');
      
      final archivalService = ArchivalService.fromEnvironment(session);
      final result = await archivalService.runMonthlyArchival();
      
      if (result.success) {
        final message = 'Manual archival completed successfully. '
                       'Users: ${result.successfulUsers}/${result.totalUsers}, '
                       'Entries archived: ${result.totalEntriesArchived}';
        session.log(message);
        return message;
      } else {
        final message = 'Manual archival failed. Errors: ${result.errors.join(', ')}';
        session.log(message, level: LogLevel.error);
        throw Exception(message);
      }
      
    } catch (e) {
      session.log('Manual archival failed: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Parse archived month data from JSON (entries only)
  ArchivedMonth _parseArchivedMonth(Map<String, dynamic> data) {
    final entries = (data['entries'] as List? ?? []).map((entryData) => 
      EncryptedEntry(
        id: entryData['id'],
        accountId: data['userId'],
        encryptedData: entryData['encryptedData'],
        updatedAt: DateTime.parse(entryData['updatedAt']),
      )
    ).toList();
    
    // For entry-only archives, templates/schedules/pipelines are empty
    // These data types are never archived and stay in PostgreSQL forever
    return ArchivedMonth(
      userId: data['userId'],
      year: DateTime.parse(data['month']).year,
      month: DateTime.parse(data['month']).month,
      entries: entries,
      templates: [], // Never archived
      schedules: [], // Never archived
      analysisPipelines: [], // Never archived
      archivedAt: DateTime.parse(data['archivedAt']),
      version: data['version'] ?? '1.0',
    );
  }

  /// Parse archive key to extract year/month info
  ({int year, int month})? _parseArchiveKey(String key) {
    // Expected format: archives/{userId}/{year}/{month}.json.gz
    final parts = key.split('/');
    if (parts.length >= 4) {
      try {
        final year = int.parse(parts[2]);
        final monthFile = parts[3]; // e.g., "01.json.gz"
        final month = int.parse(monthFile.split('.').first);
        return (year: year, month: month);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}