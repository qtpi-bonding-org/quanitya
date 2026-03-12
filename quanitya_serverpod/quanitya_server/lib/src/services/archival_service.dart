import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'r2_storage_service.dart';

/// Archival service for managing PowerSync data lifecycle
///
/// Handles monthly archival of ONLY encrypted_entries to R2 storage:
/// - Entries older than [_bufferMonths] are archived to R2, deleted from PostgreSQL
/// - Templates, schedules, analysis pipelines, aesthetics: NEVER archived (stay forever)
/// - Buffer months configurable via ARCHIVE_BUFFER_MONTHS env var (default: 6)
class ArchivalService {
  static final int _bufferMonths = int.tryParse(
        Platform.environment['ARCHIVE_BUFFER_MONTHS'] ?? '',
      ) ??
      6;
  static const int _batchSize = 100;

  final Session _session;
  final R2StorageService _r2Storage;

  ArchivalService(this._session, this._r2Storage);

  /// Run monthly archival process for entries only
  ///
  /// Archives ONLY encrypted_entries older than [_bufferMonths] months.
  /// Templates, schedules, analysis pipelines, and aesthetics stay in PostgreSQL forever.
  Future<ArchivalResult> runMonthlyArchival() async {
    final result = ArchivalResult();
    
    try {
      _session.log('Starting monthly archival process (entries only)');
      
      // Calculate target month (buffer months ago) - ONLY for entries
      final now = DateTime.now();
      final archiveMonth = DateTime(now.year, now.month - _bufferMonths, 1);
      final nextMonth = DateTime(archiveMonth.year, archiveMonth.month + 1, 1);
      
      _session.log('Archiving ENTRIES ONLY from ${archiveMonth.toIso8601String()} to ${nextMonth.toIso8601String()}');
      
      // Get all users with ENTRIES in the target month
      final usersWithEntries = await _getUsersWithEntriesInMonth(archiveMonth, nextMonth);
      result.totalUsers = usersWithEntries.length;
      
      _session.log('Found ${usersWithEntries.length} users with entries to archive');
      
      // Process users in batches
      for (int i = 0; i < usersWithEntries.length; i += _batchSize) {
        final batch = usersWithEntries.skip(i).take(_batchSize).toList();
        
        for (final userId in batch) {
          try {
            final entriesArchived = await _archiveUserEntriesForMonth(userId, archiveMonth, nextMonth);
            result.successfulUsers++;
            result.totalEntriesArchived += entriesArchived;
            
            _session.log('Archived user $userId: $entriesArchived entries');
            
          } catch (e) {
            result.failedUsers++;
            result.errors.add('User $userId: $e');
            _session.log('Failed to archive user $userId: $e', level: LogLevel.error);
          }
        }
        
        // Small delay between batches to avoid overwhelming the system
        if (i + _batchSize < usersWithEntries.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      result.success = true;
      _session.log('Monthly archival completed successfully. '
                  'Users: ${result.successfulUsers}/${result.totalUsers}, '
                  'Entries archived: ${result.totalEntriesArchived}');
      
    } catch (e) {
      result.success = false;
      result.errors.add('Archival process failed: $e');
      _session.log('Monthly archival failed: $e', level: LogLevel.error);
    }
    
    return result;
  }

  /// Archive entries for a specific user and month
  Future<int> _archiveUserEntriesForMonth(
    int userId, 
    DateTime monthStart, 
    DateTime monthEnd
  ) async {
    // Use database transaction for atomicity
    return await _session.db.transaction((transaction) async {
      // Fetch user's ENTRIES ONLY for the target month within transaction
      final entries = await _getEntriesInMonth(userId, monthStart, monthEnd);
      
      // Skip if no entries to archive
      if (entries.isEmpty) {
        return 0;
      }
      
      final key = _generateArchiveKey(userId, monthStart);
      
      // Check if already archived (idempotency)
      final alreadyArchived = await _r2Storage.verifyArchiveExists(key);
      if (alreadyArchived) {
        _session.log('Archive already exists for $key, cleaning up PostgreSQL entries');
        // Archive exists, safe to delete PostgreSQL entries
        await _deleteEntriesInTransaction(transaction, entries);
        return entries.length;
      }
      
      // Create and compress archive (entries only)
      final archiveData = _createEntryArchiveData(userId, monthStart, entries);
      final jsonBytes = utf8.encode(jsonEncode(archiveData));
      final compressed = GZipEncoder().encode(jsonBytes);
      
      // Upload to R2 (outside transaction - R2 operations can't be rolled back anyway)
      await _r2Storage.uploadArchive(key, Uint8List.fromList(compressed ?? []));
      
      // Verify upload succeeded
      final uploadVerified = await _r2Storage.verifyArchiveExists(key);
      if (!uploadVerified) {
        throw Exception('Archive upload verification failed for key: $key');
      }
      
      // Delete entries from PostgreSQL within transaction (atomic with verification)
      await _deleteEntriesInTransaction(transaction, entries);
      
      return entries.length;
    });
  }

  /// Get all users who have entries in the specified month
  Future<List<int>> _getUsersWithEntriesInMonth(DateTime monthStart, DateTime monthEnd) async {
    final entryUsers = await EncryptedEntry.db.find(
      _session,
      where: (t) => t.updatedAt.between(monthStart, monthEnd),
    );
    
    return entryUsers.map((e) => e.accountId).toSet().toList();
  }

  /// Get encrypted entries for a user in the specified month
  Future<List<EncryptedEntry>> _getEntriesInMonth(
    int userId, 
    DateTime monthStart, 
    DateTime monthEnd
  ) async {
    return await EncryptedEntry.db.find(
      _session,
      where: (t) => t.accountId.equals(userId) & 
                   t.updatedAt.between(monthStart, monthEnd),
    );
  }

  /// Create archive data structure for entries only
  Map<String, dynamic> _createEntryArchiveData(
    int userId,
    DateTime month,
    List<EncryptedEntry> entries,
  ) {
    return {
      'userId': userId,
      'month': month.toIso8601String(),
      'entryCount': entries.length,
      'dataTypes': ['encrypted_entries'],
      'entries': entries.map((e) => {
        'id': e.id,
        'type': 'encrypted_entry',
        'encryptedData': e.encryptedData,
        'updatedAt': e.updatedAt.toIso8601String(),
      }).toList(),
      'archivedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Generate R2 key for archive file
  String _generateArchiveKey(int userId, DateTime month) {
    final year = month.year;
    final monthStr = month.month.toString().padLeft(2, '0');
    return 'archives/$userId/$year/$monthStr.json.gz';
  }

  /// Delete entries from PostgreSQL within a transaction
  Future<void> _deleteEntriesInTransaction(
    Transaction transaction,
    List<EncryptedEntry> entries,
  ) async {
    for (final entry in entries) {
      await EncryptedEntry.db.deleteRow(_session, entry, transaction: transaction);
    }
  }

  /// Create archival service from environment
  static ArchivalService fromEnvironment(Session session) {
    final r2Storage = R2StorageService.fromEnvironment();
    return ArchivalService(session, r2Storage);
  }
}

/// Result of the monthly archival process
class ArchivalResult {
  bool success = false;
  int totalUsers = 0;
  int successfulUsers = 0;
  int failedUsers = 0;
  int totalEntriesArchived = 0;
  List<String> errors = [];
}