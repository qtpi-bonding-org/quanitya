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
import 'server_error_code.dart' as _i2;

abstract class ServerException
    implements _i1.SerializableException, _i1.SerializableModel {
  ServerException._({
    required this.code,
    required this.message,
  });

  factory ServerException({
    required _i2.ServerErrorCode code,
    required String message,
  }) = _ServerExceptionImpl;

  factory ServerException.fromJson(Map<String, dynamic> jsonSerialization) {
    return ServerException(
      code: _i2.ServerErrorCode.fromJson((jsonSerialization['code'] as String)),
      message: jsonSerialization['message'] as String,
    );
  }

  _i2.ServerErrorCode code;

  String message;

  /// Returns a shallow copy of this [ServerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ServerException copyWith({
    _i2.ServerErrorCode? code,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ServerException',
      'code': code.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ServerException(code: $code, message: $message)';
  }
}

class _ServerExceptionImpl extends ServerException {
  _ServerExceptionImpl({
    required _i2.ServerErrorCode code,
    required String message,
  }) : super._(
         code: code,
         message: message,
       );

  /// Returns a shallow copy of this [ServerException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ServerException copyWith({
    _i2.ServerErrorCode? code,
    String? message,
  }) {
    return ServerException(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }
}
