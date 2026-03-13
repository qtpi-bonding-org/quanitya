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
import 'rail_catalog_entry.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class PlatformCatalogResponse implements _i1.SerializableModel {
  PlatformCatalogResponse._({
    required this.platform,
    required this.rails,
  });

  factory PlatformCatalogResponse({
    required String platform,
    required List<_i2.RailCatalogEntry> rails,
  }) = _PlatformCatalogResponseImpl;

  factory PlatformCatalogResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PlatformCatalogResponse(
      platform: jsonSerialization['platform'] as String,
      rails: _i3.Protocol().deserialize<List<_i2.RailCatalogEntry>>(
        jsonSerialization['rails'],
      ),
    );
  }

  String platform;

  List<_i2.RailCatalogEntry> rails;

  /// Returns a shallow copy of this [PlatformCatalogResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PlatformCatalogResponse copyWith({
    String? platform,
    List<_i2.RailCatalogEntry>? rails,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlatformCatalogResponse',
      'platform': platform,
      'rails': rails.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PlatformCatalogResponseImpl extends PlatformCatalogResponse {
  _PlatformCatalogResponseImpl({
    required String platform,
    required List<_i2.RailCatalogEntry> rails,
  }) : super._(
         platform: platform,
         rails: rails,
       );

  /// Returns a shallow copy of this [PlatformCatalogResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PlatformCatalogResponse copyWith({
    String? platform,
    List<_i2.RailCatalogEntry>? rails,
  }) {
    return PlatformCatalogResponse(
      platform: platform ?? this.platform,
      rails: rails ?? this.rails.map((e0) => e0.copyWith()).toList(),
    );
  }
}
