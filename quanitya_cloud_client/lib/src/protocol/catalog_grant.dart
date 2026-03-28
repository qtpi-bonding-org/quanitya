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

abstract class CatalogGrant implements _i1.SerializableModel {
  CatalogGrant._({
    required this.feature,
    required this.quantity,
  });

  factory CatalogGrant({
    required _i2.Feature feature,
    required double quantity,
  }) = _CatalogGrantImpl;

  factory CatalogGrant.fromJson(Map<String, dynamic> jsonSerialization) {
    return CatalogGrant(
      feature: _i2.Feature.fromJson((jsonSerialization['feature'] as String)),
      quantity: (jsonSerialization['quantity'] as num).toDouble(),
    );
  }

  _i2.Feature feature;

  double quantity;

  /// Returns a shallow copy of this [CatalogGrant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CatalogGrant copyWith({
    _i2.Feature? feature,
    double? quantity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CatalogGrant',
      'feature': feature.toJson(),
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CatalogGrantImpl extends CatalogGrant {
  _CatalogGrantImpl({
    required _i2.Feature feature,
    required double quantity,
  }) : super._(
         feature: feature,
         quantity: quantity,
       );

  /// Returns a shallow copy of this [CatalogGrant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CatalogGrant copyWith({
    _i2.Feature? feature,
    double? quantity,
  }) {
    return CatalogGrant(
      feature: feature ?? this.feature,
      quantity: quantity ?? this.quantity,
    );
  }
}
