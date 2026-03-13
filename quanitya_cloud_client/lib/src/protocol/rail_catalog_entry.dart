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
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class RailCatalogEntry implements _i1.SerializableModel {
  RailCatalogEntry._({
    required this.rail,
    required this.status,
    required this.productIds,
  });

  factory RailCatalogEntry({
    required String rail,
    required _i2.RailStatus status,
    required List<String> productIds,
  }) = _RailCatalogEntryImpl;

  factory RailCatalogEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return RailCatalogEntry(
      rail: jsonSerialization['rail'] as String,
      status: _i2.RailStatus.fromJson((jsonSerialization['status'] as String)),
      productIds: _i3.Protocol().deserialize<List<String>>(
        jsonSerialization['productIds'],
      ),
    );
  }

  String rail;

  _i2.RailStatus status;

  List<String> productIds;

  /// Returns a shallow copy of this [RailCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RailCatalogEntry copyWith({
    String? rail,
    _i2.RailStatus? status,
    List<String>? productIds,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RailCatalogEntry',
      'rail': rail,
      'status': status.toJson(),
      'productIds': productIds.toJson(),
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
    required List<String> productIds,
  }) : super._(
         rail: rail,
         status: status,
         productIds: productIds,
       );

  /// Returns a shallow copy of this [RailCatalogEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RailCatalogEntry copyWith({
    String? rail,
    _i2.RailStatus? status,
    List<String>? productIds,
  }) {
    return RailCatalogEntry(
      rail: rail ?? this.rail,
      status: status ?? this.status,
      productIds: productIds ?? this.productIds.map((e0) => e0).toList(),
    );
  }
}
