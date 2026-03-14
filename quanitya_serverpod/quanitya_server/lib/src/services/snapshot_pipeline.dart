import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:serverpod/serverpod.dart';

import 'r2_storage_service.dart';

/// Reusable pipeline for creating verified snapshots in R2.
///
/// Handles: JSON encode -> gzip compress -> upload to R2 -> verify existence.
/// Used by both community server (user data) and cloud server (operational data).
class SnapshotPipeline {
  final R2StorageService _r2Storage;
  final Session _session;

  SnapshotPipeline(this._session, this._r2Storage);

  /// Compress and upload data to R2, then verify it exists.
  ///
  /// [key] - R2 object key (e.g., 'snapshots/user-entries/42/2026-03.json.gz')
  /// [data] - Map to JSON-encode, compress, and upload
  ///
  /// Returns true if upload succeeded and was verified, false otherwise.
  /// Throws on compression failure.
  Future<bool> uploadAndVerify(String key, Map<String, dynamic> data) async {
    // 1. JSON encode and compress
    final jsonBytes = utf8.encode(jsonEncode(data));
    final compressed = GZipEncoder().encode(jsonBytes);
    if (compressed == null || compressed.isEmpty) {
      throw Exception('Compression failed for key: $key');
    }

    // 2. Upload to R2
    await _r2Storage.uploadArchive(key, Uint8List.fromList(compressed));

    // 3. Verify upload exists
    final verified = await _r2Storage.verifyArchiveExists(key);
    if (!verified) {
      _session.log('Snapshot verification failed for $key',
          level: LogLevel.error);
    }
    return verified;
  }

  /// Create pipeline from environment variables.
  static SnapshotPipeline fromEnvironment(Session session) {
    return SnapshotPipeline(session, R2StorageService.fromEnvironment());
  }
}
