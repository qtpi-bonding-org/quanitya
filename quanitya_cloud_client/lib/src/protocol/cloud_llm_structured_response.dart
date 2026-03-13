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

abstract class CloudLlmStructuredResponse implements _i1.SerializableModel {
  CloudLlmStructuredResponse._({
    required this.resultJson,
    required this.balance,
  });

  factory CloudLlmStructuredResponse({
    required String resultJson,
    required double balance,
  }) = _CloudLlmStructuredResponseImpl;

  factory CloudLlmStructuredResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudLlmStructuredResponse(
      resultJson: jsonSerialization['resultJson'] as String,
      balance: (jsonSerialization['balance'] as num).toDouble(),
    );
  }

  String resultJson;

  double balance;

  /// Returns a shallow copy of this [CloudLlmStructuredResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudLlmStructuredResponse copyWith({
    String? resultJson,
    double? balance,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudLlmStructuredResponse',
      'resultJson': resultJson,
      'balance': balance,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CloudLlmStructuredResponseImpl extends CloudLlmStructuredResponse {
  _CloudLlmStructuredResponseImpl({
    required String resultJson,
    required double balance,
  }) : super._(
         resultJson: resultJson,
         balance: balance,
       );

  /// Returns a shallow copy of this [CloudLlmStructuredResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudLlmStructuredResponse copyWith({
    String? resultJson,
    double? balance,
  }) {
    return CloudLlmStructuredResponse(
      resultJson: resultJson ?? this.resultJson,
      balance: balance ?? this.balance,
    );
  }
}
