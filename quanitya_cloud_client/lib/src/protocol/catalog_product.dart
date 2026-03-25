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

abstract class CatalogProduct implements _i1.SerializableModel {
  CatalogProduct._({
    required this.storeProductId,
    required this.feature,
    required this.serverValidated,
  });

  factory CatalogProduct({
    required String storeProductId,
    required _i2.Feature feature,
    required bool serverValidated,
  }) = _CatalogProductImpl;

  factory CatalogProduct.fromJson(Map<String, dynamic> jsonSerialization) {
    return CatalogProduct(
      storeProductId: jsonSerialization['storeProductId'] as String,
      feature: _i2.Feature.fromJson((jsonSerialization['feature'] as String)),
      serverValidated: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['serverValidated'],
      ),
    );
  }

  String storeProductId;

  _i2.Feature feature;

  bool serverValidated;

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CatalogProduct copyWith({
    String? storeProductId,
    _i2.Feature? feature,
    bool? serverValidated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CatalogProduct',
      'storeProductId': storeProductId,
      'feature': feature.toJson(),
      'serverValidated': serverValidated,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CatalogProductImpl extends CatalogProduct {
  _CatalogProductImpl({
    required String storeProductId,
    required _i2.Feature feature,
    required bool serverValidated,
  }) : super._(
         storeProductId: storeProductId,
         feature: feature,
         serverValidated: serverValidated,
       );

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CatalogProduct copyWith({
    String? storeProductId,
    _i2.Feature? feature,
    bool? serverValidated,
  }) {
    return CatalogProduct(
      storeProductId: storeProductId ?? this.storeProductId,
      feature: feature ?? this.feature,
      serverValidated: serverValidated ?? this.serverValidated,
    );
  }
}
