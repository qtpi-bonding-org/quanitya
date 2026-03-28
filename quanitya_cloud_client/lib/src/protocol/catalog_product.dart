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
import 'catalog_grant.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class CatalogProduct implements _i1.SerializableModel {
  CatalogProduct._({
    required this.storeProductId,
    required this.grants,
    required this.serverValidated,
  });

  factory CatalogProduct({
    required String storeProductId,
    required List<_i2.CatalogGrant> grants,
    required bool serverValidated,
  }) = _CatalogProductImpl;

  factory CatalogProduct.fromJson(Map<String, dynamic> jsonSerialization) {
    return CatalogProduct(
      storeProductId: jsonSerialization['storeProductId'] as String,
      grants: _i3.Protocol().deserialize<List<_i2.CatalogGrant>>(
        jsonSerialization['grants'],
      ),
      serverValidated: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['serverValidated'],
      ),
    );
  }

  String storeProductId;

  List<_i2.CatalogGrant> grants;

  bool serverValidated;

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CatalogProduct copyWith({
    String? storeProductId,
    List<_i2.CatalogGrant>? grants,
    bool? serverValidated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CatalogProduct',
      'storeProductId': storeProductId,
      'grants': grants.toJson(valueToJson: (v) => v.toJson()),
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
    required List<_i2.CatalogGrant> grants,
    required bool serverValidated,
  }) : super._(
         storeProductId: storeProductId,
         grants: grants,
         serverValidated: serverValidated,
       );

  /// Returns a shallow copy of this [CatalogProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CatalogProduct copyWith({
    String? storeProductId,
    List<_i2.CatalogGrant>? grants,
    bool? serverValidated,
  }) {
    return CatalogProduct(
      storeProductId: storeProductId ?? this.storeProductId,
      grants: grants ?? this.grants.map((e0) => e0.copyWith()).toList(),
      serverValidated: serverValidated ?? this.serverValidated,
    );
  }
}
