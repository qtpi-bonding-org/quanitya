/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class BatchSubmissionResult implements _i1.SerializableModel {
  BatchSubmissionResult._({
    required this.accepted,
    required this.rejected,
    required this.totalSubmitted,
  });

  factory BatchSubmissionResult({
    required int accepted,
    required int rejected,
    required int totalSubmitted,
  }) = _BatchSubmissionResultImpl;

  factory BatchSubmissionResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BatchSubmissionResult(
      accepted: jsonSerialization['accepted'] as int,
      rejected: jsonSerialization['rejected'] as int,
      totalSubmitted: jsonSerialization['totalSubmitted'] as int,
    );
  }

  int accepted;

  int rejected;

  int totalSubmitted;

  /// Returns a shallow copy of this [BatchSubmissionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BatchSubmissionResult copyWith({
    int? accepted,
    int? rejected,
    int? totalSubmitted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BatchSubmissionResult',
      'accepted': accepted,
      'rejected': rejected,
      'totalSubmitted': totalSubmitted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BatchSubmissionResultImpl extends BatchSubmissionResult {
  _BatchSubmissionResultImpl({
    required int accepted,
    required int rejected,
    required int totalSubmitted,
  }) : super._(
         accepted: accepted,
         rejected: rejected,
         totalSubmitted: totalSubmitted,
       );

  /// Returns a shallow copy of this [BatchSubmissionResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BatchSubmissionResult copyWith({
    int? accepted,
    int? rejected,
    int? totalSubmitted,
  }) {
    return BatchSubmissionResult(
      accepted: accepted ?? this.accepted,
      rejected: rejected ?? this.rejected,
      totalSubmitted: totalSubmitted ?? this.totalSubmitted,
    );
  }
}
