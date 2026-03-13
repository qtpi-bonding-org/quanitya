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
import 'sync_tier_balance.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class SyncAccessInfo implements _i1.SerializableModel {
  SyncAccessInfo._({
    required this.hasAccess,
    required this.tierBalances,
  });

  factory SyncAccessInfo({
    required bool hasAccess,
    required List<_i2.SyncTierBalance> tierBalances,
  }) = _SyncAccessInfoImpl;

  factory SyncAccessInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncAccessInfo(
      hasAccess: _i1.BoolJsonExtension.fromJson(jsonSerialization['hasAccess']),
      tierBalances: _i3.Protocol().deserialize<List<_i2.SyncTierBalance>>(
        jsonSerialization['tierBalances'],
      ),
    );
  }

  bool hasAccess;

  List<_i2.SyncTierBalance> tierBalances;

  /// Returns a shallow copy of this [SyncAccessInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncAccessInfo copyWith({
    bool? hasAccess,
    List<_i2.SyncTierBalance>? tierBalances,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncAccessInfo',
      'hasAccess': hasAccess,
      'tierBalances': tierBalances.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncAccessInfoImpl extends SyncAccessInfo {
  _SyncAccessInfoImpl({
    required bool hasAccess,
    required List<_i2.SyncTierBalance> tierBalances,
  }) : super._(
         hasAccess: hasAccess,
         tierBalances: tierBalances,
       );

  /// Returns a shallow copy of this [SyncAccessInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncAccessInfo copyWith({
    bool? hasAccess,
    List<_i2.SyncTierBalance>? tierBalances,
  }) {
    return SyncAccessInfo(
      hasAccess: hasAccess ?? this.hasAccess,
      tierBalances:
          tierBalances ?? this.tierBalances.map((e0) => e0.copyWith()).toList(),
    );
  }
}
