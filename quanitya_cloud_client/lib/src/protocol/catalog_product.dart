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
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class CatalogProduct implements _i1.SerializableModel {
  CatalogProduct._({
    required this.storeProductId,
    required this.features,
    required this.serverValidated,
  });

  factory CatalogProduct({
    required String storeProductId,
    required List<_i2.Feature> features,
    required bool serverValidated,
  }) = _CatalogProductImpl;

  factory CatalogProduct.fromJson(Map<String, dynamic> jsonSerialization) {
    return CatalogProduct(
      storeProductId: jsonSerialization['storeProductId'] as String,
      features: _i3.Protocol().deserialize<List<_i2.Feature>>(
        jsonSerialization['features'],
      ),
      serverValidated: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['serverValidated'],
      ),
    );
  }

  String storeProductId;

  List<_i2.Feature> features;

  bool serverValidated;

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CatalogProduct copyWith({
    String? storeProductId,
    List<_i2.Feature>? features,
    bool? serverValidated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CatalogProduct',
      'storeProductId': storeProductId,
      'features': features.toJson(valueToJson: (v) => v.toJson()),
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
    required List<_i2.Feature> features,
    required bool serverValidated,
  }) : super._(
         storeProductId: storeProductId,
         features: features,
         serverValidated: serverValidated,
       );

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CatalogProduct copyWith({
    String? storeProductId,
    List<_i2.Feature>? features,
    bool? serverValidated,
  }) {
    return CatalogProduct(
      storeProductId: storeProductId ?? this.storeProductId,
      features: features ?? this.features.map((e0) => e0).toList(),
      serverValidated: serverValidated ?? this.serverValidated,
    );
  }
}
