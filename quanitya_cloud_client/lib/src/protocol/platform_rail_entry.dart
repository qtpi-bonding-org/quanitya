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

abstract class PlatformRailEntry implements _i1.SerializableModel {
  PlatformRailEntry._({
    required this.rail,
    required this.status,
  });

  factory PlatformRailEntry({
    required String rail,
    required String status,
  }) = _PlatformRailEntryImpl;

  factory PlatformRailEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlatformRailEntry(
      rail: jsonSerialization['rail'] as String,
      status: jsonSerialization['status'] as String,
    );
  }

  String rail;

  String status;

  /// Returns a shallow copy of this [PlatformRailEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PlatformRailEntry copyWith({
    String? rail,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlatformRailEntry',
      'rail': rail,
      'status': status,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PlatformRailEntryImpl extends PlatformRailEntry {
  _PlatformRailEntryImpl({
    required String rail,
    required String status,
  }) : super._(
         rail: rail,
         status: status,
       );

  /// Returns a shallow copy of this [PlatformRailEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PlatformRailEntry copyWith({
    String? rail,
    String? status,
  }) {
    return PlatformRailEntry(
      rail: rail ?? this.rail,
      status: status ?? this.status,
    );
  }
}
