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

abstract class ApiResponse implements _i1.SerializableModel {
  ApiResponse._({
    required this.success,
    this.message,
    this.errorCode,
    this.jsonData,
  });

  factory ApiResponse({
    required bool success,
    String? message,
    String? errorCode,
    String? jsonData,
  }) = _ApiResponseImpl;

  factory ApiResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiResponse(
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      message: jsonSerialization['message'] as String?,
      errorCode: jsonSerialization['errorCode'] as String?,
      jsonData: jsonSerialization['jsonData'] as String?,
    );
  }

  bool success;

  String? message;

  String? errorCode;

  String? jsonData;

  /// Returns a shallow copy of this [ApiResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiResponse copyWith({
    bool? success,
    String? message,
    String? errorCode,
    String? jsonData,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiResponse',
      'success': success,
      if (message != null) 'message': message,
      if (errorCode != null) 'errorCode': errorCode,
      if (jsonData != null) 'jsonData': jsonData,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiResponseImpl extends ApiResponse {
  _ApiResponseImpl({
    required bool success,
    String? message,
    String? errorCode,
    String? jsonData,
  }) : super._(
         success: success,
         message: message,
         errorCode: errorCode,
         jsonData: jsonData,
       );

  /// Returns a shallow copy of this [ApiResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiResponse copyWith({
    bool? success,
    Object? message = _Undefined,
    Object? errorCode = _Undefined,
    Object? jsonData = _Undefined,
  }) {
    return ApiResponse(
      success: success ?? this.success,
      message: message is String? ? message : this.message,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      jsonData: jsonData is String? ? jsonData : this.jsonData,
    );
  }
}
