import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:injectable/injectable.dart';
import '../config/debug_log.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'dart:io' show Platform;

import '../public_submission/public_submission_service.dart';

const _tag = 'infrastructure/error_reporting/error_reporter_service';

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

  /// Send a single error report to server with proof-of-work and signature.
  ///
  /// Wraps the single report in a batch call to [submitErrorReports].
  /// Returns true if successfully sent, false otherwise.
  /// Never throws - error reporting should never crash the app.
  Future<bool> sendErrorReport(ErrorEntry errorEntry) async {
    final result = await sendErrorReports([errorEntry]);
    return result > 0;
  }

  /// Send a batch of error reports with a single PoW + ECDSA verification.
  ///
  /// Returns the number of reports successfully inserted on the server.
  /// Never throws - error reporting should never crash the app.
  Future<int> sendErrorReports(List<ErrorEntry> entries) async {
    if (entries.isEmpty) return 0;

    try {
      final platform = _getPlatformName();
      final reportsJson = jsonEncode(
        entries.map((e) => {
          'source': e.source,
          'errorType': e.errorType,
          'errorCode': e.errorCode,
          'stackTrace': e.stackTrace,
          'clientTimestamp': e.timestamp.toIso8601String(),
          'userMessage': e.userMessage,
          'platform': platform,
        }).toList(),
      );

      final payloadSuffix = 'errorReports:${entries.length}';

      await _submissionService.submitWithVerification(
        endpoint: 'errorReport',
        payload: payloadSuffix,
        submitCallback: (challenge, proofOfWork, publicKeyHex, signature) async {
          await _client.errorReport.submitErrorReports(
            challenge: challenge,
            proofOfWork: proofOfWork,
            publicKeyHex: publicKeyHex,
            signature: signature,
            reportsJson: reportsJson,
          );
        },
      );

      Log.d(_tag, 'Error reports batch sent: ${entries.length}');
      return entries.length;
    } catch (e) {
      Log.d(_tag, 'Error sending reports batch: $e');
      return 0;
    }
  }

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
