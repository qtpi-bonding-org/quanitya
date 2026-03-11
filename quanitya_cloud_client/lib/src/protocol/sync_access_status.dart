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

abstract class SyncAccessStatus implements _i1.SerializableModel {
  SyncAccessStatus._({
    required this.hasAccess,
    required this.syncDaysRemaining,
    this.accessExpiry,
    required this.needsTopUp,
  });

  factory SyncAccessStatus({
    required bool hasAccess,
    required int syncDaysRemaining,
    DateTime? accessExpiry,
    required bool needsTopUp,
  }) = _SyncAccessStatusImpl;

  factory SyncAccessStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncAccessStatus(
      hasAccess: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasAccess']),
      syncDaysRemaining: jsonSerialization['syncDaysRemaining'] as int,
      accessExpiry: jsonSerialization['accessExpiry'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['accessExpiry'],
            ),
      needsTopUp: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['needsTopUp'],
      ),
    );
  }

  bool hasAccess;

  int syncDaysRemaining;

  DateTime? accessExpiry;

  bool needsTopUp;

  /// Returns a shallow copy of this [SyncAccessStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncAccessStatus copyWith({
    bool? hasAccess,
    int? syncDaysRemaining,
    DateTime? accessExpiry,
    bool? needsTopUp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncAccessStatus',
      'hasAccess': hasAccess,
      'syncDaysRemaining': syncDaysRemaining,
      if (accessExpiry != null) 'accessExpiry': accessExpiry?.toJson(),
      'needsTopUp': needsTopUp,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncAccessStatusImpl extends SyncAccessStatus {
  _SyncAccessStatusImpl({
    required bool hasAccess,
    required int syncDaysRemaining,
    DateTime? accessExpiry,
    required bool needsTopUp,
  }) : super._(
         hasAccess: hasAccess,
         syncDaysRemaining: syncDaysRemaining,
         accessExpiry: accessExpiry,
         needsTopUp: needsTopUp,
       );

  /// Returns a shallow copy of this [SyncAccessStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncAccessStatus copyWith({
    bool? hasAccess,
    int? syncDaysRemaining,
    Object? accessExpiry = _Undefined,
    bool? needsTopUp,
  }) {
    return SyncAccessStatus(
      hasAccess: hasAccess ?? this.hasAccess,
      syncDaysRemaining: syncDaysRemaining ?? this.syncDaysRemaining,
      accessExpiry: accessExpiry is DateTime?
          ? accessExpiry
          : this.accessExpiry,
      needsTopUp: needsTopUp ?? this.needsTopUp,
    );
  }
}
