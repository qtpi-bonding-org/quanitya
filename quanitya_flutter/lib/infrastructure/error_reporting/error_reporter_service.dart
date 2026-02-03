import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'dart:io' show Platform;

import '../public_submission/public_submission_service.dart';

/// Service for sending error reports to the server.
/// 
/// Handles the actual transmission of privacy-preserving error data
/// to developers for debugging purposes.
/// 
/// Uses PublicSubmissionService for challenge-response + PoW + signature.
@lazySingleton
class ErrorReporterService {
  final Client _client;
  final PublicSubmissionService _submissionService;
  
  ErrorReporterService(
    this._client,
    this._submissionService,
  );
  
  /// Send error report to server with proof-of-work and signature.
  /// 
  /// The ErrorEntry is already PII-free by design, so this method
  /// can safely transmit all the technical debugging information.
  /// 
  /// Returns true if successfully sent, false otherwise.
  /// Never throws - error reporting should never crash the app.
  Future<bool> sendErrorReport(ErrorEntry errorEntry) async {
    try {
      // Build payload for signing
      // Format: "source:errorType:errorCode:timestamp"
      // Note: challenge will be prepended by submitWithVerification
      final timestamp = errorEntry.timestamp.toIso8601String();
      final payloadSuffix = '${errorEntry.source}:${errorEntry.errorType}:'
          '${errorEntry.errorCode}:$timestamp';
      
      // Submit via PublicSubmissionService
      final response = await _submissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: payloadSuffix, // Challenge prepended automatically
        submitCallback: (challenge, proofOfWork, publicKeyHex, signature) async {
          return await _client.errorReport.submitErrorReport(
            challenge: challenge,
            proofOfWork: proofOfWork,
            publicKeyHex: publicKeyHex,
            signature: signature,
            source: errorEntry.source,
            errorType: errorEntry.errorType,
            errorCode: errorEntry.errorCode,
            stackTrace: errorEntry.stackTrace,
            clientTimestamp: errorEntry.timestamp,
            userMessage: errorEntry.userMessage,
            appVersion: null, // TODO: Add package_info_plus if needed
            platform: _getPlatformName(),
            deviceInfo: null, // Could add device_info_plus if needed
          );
        },
      );
      
      if (response.success) {
        final reportId = response.data?['reportId'];
        debugPrint('📤 Error report sent successfully: ${errorEntry.errorCode} (ID: $reportId)');
        return true;
      } else {
        debugPrint('📤 Failed to send error report: ${response.message}');
        return false;
      }
    } catch (e) {
      // Never throw - error reporting should never crash the app
      debugPrint('📤 Error sending report: $e');
      return false;
    }
  }
  
  /// Get platform name for error reporting
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
