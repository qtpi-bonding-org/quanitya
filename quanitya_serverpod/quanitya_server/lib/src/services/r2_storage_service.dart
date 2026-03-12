import 'dart:io';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';

/// R2 (Cloudflare) storage service for archival data
/// 
/// Handles upload, download, and verification of archived data files.
/// Uses S3-compatible API with Cloudflare R2 endpoints.
class R2StorageService {
  late final S3 _s3Client;
  final String _bucketName;
  
  R2StorageService({
    required String accountId,
    required String accessKeyId,
    required String secretAccessKey,
    required String bucketName,
  }) : _bucketName = bucketName {
    _s3Client = S3(
      region: 'auto',
      credentials: AwsClientCredentials(
        accessKey: accessKeyId,
        secretKey: secretAccessKey,
      ),
      endpointUrl: 'https://$accountId.r2.cloudflarestorage.com',
    );
  }

  /// Upload compressed archive data to R2
  /// 
  /// [key] - R2 object key (e.g., 'archives/12345/2024/01.json.gz')
  /// [data] - Compressed archive data
  /// 
  /// Returns true if upload successful, throws exception on failure
  Future<bool> uploadArchive(String key, Uint8List data) async {
    try {
      await _s3Client.putObject(
        bucket: _bucketName,
        key: key,
        body: data,
        contentType: 'application/gzip',
        contentEncoding: 'gzip',
        metadata: {
          'archive-version': '1.0',
          'uploaded-at': DateTime.now().toIso8601String(),
        },
      );
      
      return true;
    } catch (e) {
      throw Exception('Failed to upload archive to R2: $e');
    }
  }

  /// Download archive data from R2
  /// 
  /// [key] - R2 object key
  /// 
  /// Returns compressed archive data, throws exception if not found
  Future<Uint8List> downloadArchive(String key) async {
    try {
      final response = await _s3Client.getObject(
        bucket: _bucketName,
        key: key,
      );
      
      if (response.body == null) {
        throw Exception('Archive not found: $key');
      }
      
      return response.body!;
    } catch (e) {
      throw Exception('Failed to download archive from R2: $e');
    }
  }

  /// Verify that an archive exists and is accessible
  /// 
  /// [key] - R2 object key
  /// 
  /// Returns true if archive exists and is accessible
  Future<bool> verifyArchiveExists(String key) async {
    try {
      await _s3Client.headObject(
        bucket: _bucketName,
        key: key,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all archives for a specific user
  ///
  /// [userId] - User ID to list archives for
  ///
  /// Returns list of archive keys (file paths)
  Future<List<String>> listUserArchives(int userId) async {
    return listArchives('archives/$userId/');
  }

  /// List all archives matching a prefix
  ///
  /// [prefix] - Prefix to list archives for (e.g., 'error-reports/')
  ///
  /// Returns list of archive keys (file paths)
  Future<List<String>> listArchives(String prefix) async {
    try {
      final response = await _s3Client.listObjectsV2(
        bucket: _bucketName,
        prefix: prefix,
      );

      return response.contents?.map((obj) => obj.key!).toList() ?? [];
    } catch (e) {
      throw Exception('Failed to list archives: $e');
    }
  }

  /// Delete an archive (for cleanup or error recovery)
  /// 
  /// [key] - R2 object key to delete
  /// 
  /// Returns true if deletion successful
  Future<bool> deleteArchive(String key) async {
    try {
      await _s3Client.deleteObject(
        bucket: _bucketName,
        key: key,
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete archive: $e');
    }
  }

  /// Get archive metadata without downloading full content
  /// 
  /// [key] - R2 object key
  /// 
  /// Returns metadata map or null if not found
  Future<Map<String, String>?> getArchiveMetadata(String key) async {
    try {
      final response = await _s3Client.headObject(
        bucket: _bucketName,
        key: key,
      );
      
      return response.metadata;
    } catch (e) {
      return null;
    }
  }

  /// Create R2 storage service from environment variables
  /// 
  /// Expected environment variables:
  /// - R2_ACCOUNT_ID
  /// - R2_ACCESS_KEY_ID  
  /// - R2_SECRET_ACCESS_KEY
  /// - R2_BUCKET_NAME
  static R2StorageService fromEnvironment() {
    final accountId = Platform.environment['R2_ACCOUNT_ID'];
    final accessKeyId = Platform.environment['R2_ACCESS_KEY_ID'];
    final secretAccessKey = Platform.environment['R2_SECRET_ACCESS_KEY'];
    final bucketName = Platform.environment['R2_BUCKET_NAME'];

    if (accountId == null || accessKeyId == null || 
        secretAccessKey == null || bucketName == null) {
      throw Exception(
        'Missing R2 configuration. Required environment variables: '
        'R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME'
      );
    }

    return R2StorageService(
      accountId: accountId,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      bucketName: bucketName,
    );
  }
}