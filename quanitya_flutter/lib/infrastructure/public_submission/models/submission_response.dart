import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

part 'submission_response.freezed.dart';
part 'submission_response.g.dart';

/// Response from server's submit endpoint.
@freezed
class SubmissionResponse with _$SubmissionResponse {
  const factory SubmissionResponse({
    required bool success,
    required String message,
    Map<String, dynamic>? data,
  }) = _SubmissionResponse;

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmissionResponseFromJson(json);

  /// Create from typed Serverpod ApiResponse.
  factory SubmissionResponse.fromApiResponse(ApiResponse result) {
    Map<String, dynamic>? data;
    if (result.jsonData != null) {
      try {
        data = jsonDecode(result.jsonData!) as Map<String, dynamic>;
      } catch (_) {
        // If jsonData isn't valid JSON, ignore it
      }
    }
    return SubmissionResponse(
      success: result.success,
      message: result.message ?? '',
      data: data,
    );
  }
}
