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

abstract class StorageUsageResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StorageUsageResponse._({
    required this.bytesUsed,
    required this.bytesLimit,
    required this.rowCount,
    required this.percentUsed,
    required this.bytesRemaining,
  });

  factory StorageUsageResponse({
    required int bytesUsed,
    required int bytesLimit,
    required int rowCount,
    required int percentUsed,
    required int bytesRemaining,
  }) = _StorageUsageResponseImpl;

  factory StorageUsageResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StorageUsageResponse(
      bytesUsed: jsonSerialization['bytesUsed'] as int,
      bytesLimit: jsonSerialization['bytesLimit'] as int,
      rowCount: jsonSerialization['rowCount'] as int,
      percentUsed: jsonSerialization['percentUsed'] as int,
      bytesRemaining: jsonSerialization['bytesRemaining'] as int,
    );
  }

  int bytesUsed;

  int bytesLimit;

  int rowCount;

  int percentUsed;

  int bytesRemaining;

  /// Returns a shallow copy of this [StorageUsageResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StorageUsageResponse copyWith({
    int? bytesUsed,
    int? bytesLimit,
    int? rowCount,
    int? percentUsed,
    int? bytesRemaining,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.StorageUsageResponse',
      'bytesUsed': bytesUsed,
      'bytesLimit': bytesLimit,
      'rowCount': rowCount,
      'percentUsed': percentUsed,
      'bytesRemaining': bytesRemaining,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.StorageUsageResponse',
      'bytesUsed': bytesUsed,
      'bytesLimit': bytesLimit,
      'rowCount': rowCount,
      'percentUsed': percentUsed,
      'bytesRemaining': bytesRemaining,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StorageUsageResponseImpl extends StorageUsageResponse {
  _StorageUsageResponseImpl({
    required int bytesUsed,
    required int bytesLimit,
    required int rowCount,
    required int percentUsed,
    required int bytesRemaining,
  }) : super._(
         bytesUsed: bytesUsed,
         bytesLimit: bytesLimit,
         rowCount: rowCount,
         percentUsed: percentUsed,
         bytesRemaining: bytesRemaining,
       );

  /// Returns a shallow copy of this [StorageUsageResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StorageUsageResponse copyWith({
    int? bytesUsed,
    int? bytesLimit,
    int? rowCount,
    int? percentUsed,
    int? bytesRemaining,
  }) {
    return StorageUsageResponse(
      bytesUsed: bytesUsed ?? this.bytesUsed,
      bytesLimit: bytesLimit ?? this.bytesLimit,
      rowCount: rowCount ?? this.rowCount,
      percentUsed: percentUsed ?? this.percentUsed,
      bytesRemaining: bytesRemaining ?? this.bytesRemaining,
    );
  }
}
