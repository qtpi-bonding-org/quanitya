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
import 'package:anonaccred_client/anonaccred_client.dart' as _i2;
import 'feature.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i4;

abstract class AppEntitlement implements _i1.SerializableModel {
  AppEntitlement._({
    this.id,
    required this.entitlementId,
    this.entitlement,
    required this.feature,
  });

  factory AppEntitlement({
    int? id,
    required int entitlementId,
    _i2.Entitlement? entitlement,
    required _i3.Feature feature,
  }) = _AppEntitlementImpl;

  factory AppEntitlement.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppEntitlement(
      id: jsonSerialization['id'] as int?,
      entitlementId: jsonSerialization['entitlementId'] as int,
      entitlement: jsonSerialization['entitlement'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Entitlement>(
              jsonSerialization['entitlement'],
            ),
      feature: _i3.Feature.fromJson((jsonSerialization['feature'] as String)),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int entitlementId;

  _i2.Entitlement? entitlement;

  _i3.Feature feature;

  /// Returns a shallow copy of this [AppEntitlement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AppEntitlement copyWith({
    int? id,
    int? entitlementId,
    _i2.Entitlement? entitlement,
    _i3.Feature? feature,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppEntitlement',
      if (id != null) 'id': id,
      'entitlementId': entitlementId,
      if (entitlement != null) 'entitlement': entitlement?.toJson(),
      'feature': feature.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppEntitlementImpl extends AppEntitlement {
  _AppEntitlementImpl({
    int? id,
    required int entitlementId,
    _i2.Entitlement? entitlement,
    required _i3.Feature feature,
  }) : super._(
         id: id,
         entitlementId: entitlementId,
         entitlement: entitlement,
         feature: feature,
       );

  /// Returns a shallow copy of this [AppEntitlement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AppEntitlement copyWith({
    Object? id = _Undefined,
    int? entitlementId,
    Object? entitlement = _Undefined,
    _i3.Feature? feature,
  }) {
    return AppEntitlement(
      id: id is int? ? id : this.id,
      entitlementId: entitlementId ?? this.entitlementId,
      entitlement: entitlement is _i2.Entitlement?
          ? entitlement
          : this.entitlement?.copyWith(),
      feature: feature ?? this.feature,
    );
  }
}
