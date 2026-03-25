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
import 'feature.dart' as _i2;
import 'package:anonaccred_client/anonaccred_client.dart' as _i3;

abstract class AccountFeatureEntitlement implements _i1.SerializableModel {
  AccountFeatureEntitlement._({
    required this.tag,
    required this.feature,
    required this.type,
    required this.balance,
  });

  factory AccountFeatureEntitlement({
    required String tag,
    required _i2.Feature feature,
    required _i3.EntitlementType type,
    required double balance,
  }) = _AccountFeatureEntitlementImpl;

  factory AccountFeatureEntitlement.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AccountFeatureEntitlement(
      tag: jsonSerialization['tag'] as String,
      feature: _i2.Feature.fromJson((jsonSerialization['feature'] as String)),
      type: _i3.EntitlementType.fromJson((jsonSerialization['type'] as String)),
      balance: (jsonSerialization['balance'] as num).toDouble(),
    );
  }

  String tag;

  _i2.Feature feature;

  _i3.EntitlementType type;

  double balance;

  /// Returns a shallow copy of this [AccountFeatureEntitlement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccountFeatureEntitlement copyWith({
    String? tag,
    _i2.Feature? feature,
    _i3.EntitlementType? type,
    double? balance,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountFeatureEntitlement',
      'tag': tag,
      'feature': feature.toJson(),
      'type': type.toJson(),
      'balance': balance,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AccountFeatureEntitlementImpl extends AccountFeatureEntitlement {
  _AccountFeatureEntitlementImpl({
    required String tag,
    required _i2.Feature feature,
    required _i3.EntitlementType type,
    required double balance,
  }) : super._(
         tag: tag,
         feature: feature,
         type: type,
         balance: balance,
       );

  /// Returns a shallow copy of this [AccountFeatureEntitlement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccountFeatureEntitlement copyWith({
    String? tag,
    _i2.Feature? feature,
    _i3.EntitlementType? type,
    double? balance,
  }) {
    return AccountFeatureEntitlement(
      tag: tag ?? this.tag,
      feature: feature ?? this.feature,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}
