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

abstract class AccountStorageUsage implements _i1.SerializableModel {
  AccountStorageUsage._({
    this.id,
    required this.accountId,
    required this.bytesUsed,
    required this.rowCount,
    required this.bytesLimit,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory AccountStorageUsage({
    int? id,
    required int accountId,
    required int bytesUsed,
    required int rowCount,
    required int bytesLimit,
    DateTime? updatedAt,
  }) = _AccountStorageUsageImpl;

  factory AccountStorageUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountStorageUsage(
      id: jsonSerialization['id'] as int?,
      accountId: jsonSerialization['accountId'] as int,
      bytesUsed: jsonSerialization['bytesUsed'] as int,
      rowCount: jsonSerialization['rowCount'] as int,
      bytesLimit: jsonSerialization['bytesLimit'] as int,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int accountId;

  int bytesUsed;

  int rowCount;

  int bytesLimit;

  DateTime updatedAt;

  /// Returns a shallow copy of this [AccountStorageUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountStorageUsage copyWith({
    int? id,
    int? accountId,
    int? bytesUsed,
    int? rowCount,
    int? bytesLimit,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.AccountStorageUsage',
      if (id != null) 'id': id,
      'accountId': accountId,
      'bytesUsed': bytesUsed,
      'rowCount': rowCount,
      'bytesLimit': bytesLimit,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountStorageUsageImpl extends AccountStorageUsage {
  _AccountStorageUsageImpl({
    int? id,
    required int accountId,
    required int bytesUsed,
    required int rowCount,
    required int bytesLimit,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountId: accountId,
         bytesUsed: bytesUsed,
         rowCount: rowCount,
         bytesLimit: bytesLimit,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AccountStorageUsage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountStorageUsage copyWith({
    Object? id = _Undefined,
    int? accountId,
    int? bytesUsed,
    int? rowCount,
    int? bytesLimit,
    DateTime? updatedAt,
  }) {
    return AccountStorageUsage(
      id: id is int? ? id : this.id,
      accountId: accountId ?? this.accountId,
      bytesUsed: bytesUsed ?? this.bytesUsed,
      rowCount: rowCount ?? this.rowCount,
      bytesLimit: bytesLimit ?? this.bytesLimit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
