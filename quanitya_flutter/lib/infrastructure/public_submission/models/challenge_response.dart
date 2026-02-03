import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge_response.freezed.dart';
part 'challenge_response.g.dart';

/// Response from server's getChallenge() endpoint.
@freezed
class ChallengeResponse with _$ChallengeResponse {
  const factory ChallengeResponse({
    required String challenge,
    required int difficulty,
    required int expiresAt,
  }) = _ChallengeResponse;
  
  factory ChallengeResponse.fromJson(Map<String, dynamic> json) =>
      _$ChallengeResponseFromJson(json);
  
  /// Create from server response (handles nested 'data' key if present).
  factory ChallengeResponse.fromServerResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return ChallengeResponse(
      challenge: data['challenge'] as String,
      difficulty: data['difficulty'] as int,
      expiresAt: data['expiresAt'] as int,
    );
  }
}
