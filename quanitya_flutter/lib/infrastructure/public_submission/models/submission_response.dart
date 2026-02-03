import 'package:freezed_annotation/freezed_annotation.dart';

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
  
  /// Create from server response.
  factory SubmissionResponse.fromServerResponse(Map<String, dynamic> response) {
    return SubmissionResponse(
      success: response['success'] as bool? ?? false,
      message: response['message'] as String? ?? '',
      data: response['data'] as Map<String, dynamic>?,
    );
  }
}
