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
import 'cloud_llm_call_type.dart' as _i2;

abstract class CloudLlmStructuredRequest implements _i1.SerializableModel {
  CloudLlmStructuredRequest._({
    required this.systemPrompt,
    required this.userPrompt,
    required this.jsonSchema,
    required this.callType,
    this.model,
  });

  factory CloudLlmStructuredRequest({
    required String systemPrompt,
    required String userPrompt,
    required String jsonSchema,
    required _i2.CloudLlmCallType callType,
    String? model,
  }) = _CloudLlmStructuredRequestImpl;

  factory CloudLlmStructuredRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CloudLlmStructuredRequest(
      systemPrompt: jsonSerialization['systemPrompt'] as String,
      userPrompt: jsonSerialization['userPrompt'] as String,
      jsonSchema: jsonSerialization['jsonSchema'] as String,
      callType: _i2.CloudLlmCallType.fromJson(
        (jsonSerialization['callType'] as String),
      ),
      model: jsonSerialization['model'] as String?,
    );
  }

  String systemPrompt;

  String userPrompt;

  String jsonSchema;

  _i2.CloudLlmCallType callType;

  String? model;

  /// Returns a shallow copy of this [CloudLlmStructuredRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CloudLlmStructuredRequest copyWith({
    String? systemPrompt,
    String? userPrompt,
    String? jsonSchema,
    _i2.CloudLlmCallType? callType,
    String? model,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CloudLlmStructuredRequest',
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'jsonSchema': jsonSchema,
      'callType': callType.toJson(),
      if (model != null) 'model': model,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CloudLlmStructuredRequestImpl extends CloudLlmStructuredRequest {
  _CloudLlmStructuredRequestImpl({
    required String systemPrompt,
    required String userPrompt,
    required String jsonSchema,
    required _i2.CloudLlmCallType callType,
    String? model,
  }) : super._(
         systemPrompt: systemPrompt,
         userPrompt: userPrompt,
         jsonSchema: jsonSchema,
         callType: callType,
         model: model,
       );

  /// Returns a shallow copy of this [CloudLlmStructuredRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CloudLlmStructuredRequest copyWith({
    String? systemPrompt,
    String? userPrompt,
    String? jsonSchema,
    _i2.CloudLlmCallType? callType,
    Object? model = _Undefined,
  }) {
    return CloudLlmStructuredRequest(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPrompt: userPrompt ?? this.userPrompt,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      callType: callType ?? this.callType,
      model: model is String? ? model : this.model,
    );
  }
}
