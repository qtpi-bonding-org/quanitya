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

abstract class StorageUsageResponse implements _i1.SerializableModel {
  StorageUsageResponse._({
    required this.bytesUsed,
    required this.rowCount,
  });

  factory StorageUsageResponse({
    required int bytesUsed,
    required int rowCount,
  }) = _StorageUsageResponseImpl;

  factory StorageUsageResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StorageUsageResponse(
      bytesUsed: jsonSerialization['bytesUsed'] as int,
      rowCount: jsonSerialization['rowCount'] as int,
    );
  }

  int bytesUsed;

  int rowCount;

  /// Returns a shallow copy of this [StorageUsageResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StorageUsageResponse copyWith({
    int? bytesUsed,
    int? rowCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.StorageUsageResponse',
      'bytesUsed': bytesUsed,
      'rowCount': rowCount,
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
    required int rowCount,
  }) : super._(
         bytesUsed: bytesUsed,
         rowCount: rowCount,
       );

  /// Returns a shallow copy of this [StorageUsageResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StorageUsageResponse copyWith({
    int? bytesUsed,
    int? rowCount,
  }) {
    return StorageUsageResponse(
      bytesUsed: bytesUsed ?? this.bytesUsed,
      rowCount: rowCount ?? this.rowCount,
    );
  }
}
