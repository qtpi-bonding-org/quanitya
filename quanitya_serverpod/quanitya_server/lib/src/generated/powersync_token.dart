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
import 'package:serverpod/serverpod.dart' as _i1;

/// PowerSync token response model
/// Used by PowerSyncEndpoint.getToken() to return JWT credentials
abstract class PowerSyncToken
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PowerSyncToken._({
    required this.token,
    required this.expiresAt,
    required this.endpoint,
  });

  factory PowerSyncToken({
    required String token,
    required String expiresAt,
    required String endpoint,
  }) = _PowerSyncTokenImpl;

  factory PowerSyncToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return PowerSyncToken(
      token: jsonSerialization['token'] as String,
      expiresAt: jsonSerialization['expiresAt'] as String,
      endpoint: jsonSerialization['endpoint'] as String,
    );
  }

  /// JWT token for PowerSync authentication
  String token;

  /// ISO8601 timestamp when token expires
  String expiresAt;

  /// PowerSync service endpoint URL
  String endpoint;

  /// Returns a shallow copy of this [PowerSyncToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PowerSyncToken copyWith({
    String? token,
    String? expiresAt,
    String? endpoint,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.PowerSyncToken',
      'token': token,
      'expiresAt': expiresAt,
      'endpoint': endpoint,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.PowerSyncToken',
      'token': token,
      'expiresAt': expiresAt,
      'endpoint': endpoint,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PowerSyncTokenImpl extends PowerSyncToken {
  _PowerSyncTokenImpl({
    required String token,
    required String expiresAt,
    required String endpoint,
  }) : super._(
         token: token,
         expiresAt: expiresAt,
         endpoint: endpoint,
       );

  /// Returns a shallow copy of this [PowerSyncToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PowerSyncToken copyWith({
    String? token,
    String? expiresAt,
    String? endpoint,
  }) {
    return PowerSyncToken(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      endpoint: endpoint ?? this.endpoint,
    );
  }
}
