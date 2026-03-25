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
import 'rail_status.dart' as _i2;
import 'catalog_product.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i4;

abstract class RailCatalogEntry implements _i1.SerializableModel {
  RailCatalogEntry._({
    required this.rail,
    required this.status,
    required this.products,
  });

  factory RailCatalogEntry({
    required String rail,
    required _i2.RailStatus status,
    required List<_i3.CatalogProduct> products,
  }) = _RailCatalogEntryImpl;

  factory RailCatalogEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return RailCatalogEntry(
      rail: jsonSerialization['rail'] as String,
      status: _i2.RailStatus.fromJson((jsonSerialization['status'] as String)),
      products: _i4.Protocol().deserialize<List<_i3.CatalogProduct>>(
        jsonSerialization['products'],
      ),
    );
  }

  String rail;

  _i2.RailStatus status;

  List<_i3.CatalogProduct> products;

  /// Returns a shallow copy of this [RailCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RailCatalogEntry copyWith({
    String? rail,
    _i2.RailStatus? status,
    List<_i3.CatalogProduct>? products,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RailCatalogEntry',
      'rail': rail,
      'status': status.toJson(),
      'products': products.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _RailCatalogEntryImpl extends RailCatalogEntry {
  _RailCatalogEntryImpl({
    required String rail,
    required _i2.RailStatus status,
    required List<_i3.CatalogProduct> products,
  }) : super._(
         rail: rail,
         status: status,
         products: products,
       );

  /// Returns a shallow copy of this [RailCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RailCatalogEntry copyWith({
    String? rail,
    _i2.RailStatus? status,
    List<_i3.CatalogProduct>? products,
  }) {
    return RailCatalogEntry(
      rail: rail ?? this.rail,
      status: status ?? this.status,
      products: products ?? this.products.map((e0) => e0.copyWith()).toList(),
    );
  }
}
