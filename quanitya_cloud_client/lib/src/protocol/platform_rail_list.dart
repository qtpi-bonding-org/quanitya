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
import 'platform_rail_entry.dart' as _i2;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class PlatformRailList implements _i1.SerializableModel {
  PlatformRailList._({required this.items});

  factory PlatformRailList({required List<_i2.PlatformRailEntry> items}) =
      _PlatformRailListImpl;

  factory PlatformRailList.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlatformRailList(
      items: _i3.Protocol().deserialize<List<_i2.PlatformRailEntry>>(
        jsonSerialization['items'],
      ),
    );
  }

  List<_i2.PlatformRailEntry> items;

  /// Returns a shallow copy of this [PlatformRailList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PlatformRailList copyWith({List<_i2.PlatformRailEntry>? items});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlatformRailList',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PlatformRailListImpl extends PlatformRailList {
  _PlatformRailListImpl({required List<_i2.PlatformRailEntry> items})
    : super._(items: items);

  /// Returns a shallow copy of this [PlatformRailList]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PlatformRailList copyWith({List<_i2.PlatformRailEntry>? items}) {
    return PlatformRailList(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
