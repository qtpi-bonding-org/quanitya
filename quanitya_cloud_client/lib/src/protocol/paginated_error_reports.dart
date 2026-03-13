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
import 'error_report.dart' as _i2;
import 'admin_pagination_info.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i4;

abstract class PaginatedErrorReports implements _i1.SerializableModel {
  PaginatedErrorReports._({
    required this.items,
    required this.pagination,
  });

  factory PaginatedErrorReports({
    required List<_i2.ErrorReport> items,
    required _i3.AdminPaginationInfo pagination,
  }) = _PaginatedErrorReportsImpl;

  factory PaginatedErrorReports.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PaginatedErrorReports(
      items: _i4.Protocol().deserialize<List<_i2.ErrorReport>>(
        jsonSerialization['items'],
      ),
      pagination: _i4.Protocol().deserialize<_i3.AdminPaginationInfo>(
        jsonSerialization['pagination'],
      ),
    );
  }

  List<_i2.ErrorReport> items;

  _i3.AdminPaginationInfo pagination;

  /// Returns a shallow copy of this [PaginatedErrorReports]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaginatedErrorReports copyWith({
    List<_i2.ErrorReport>? items,
    _i3.AdminPaginationInfo? pagination,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaginatedErrorReports',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PaginatedErrorReportsImpl extends PaginatedErrorReports {
  _PaginatedErrorReportsImpl({
    required List<_i2.ErrorReport> items,
    required _i3.AdminPaginationInfo pagination,
  }) : super._(
         items: items,
         pagination: pagination,
       );

  /// Returns a shallow copy of this [PaginatedErrorReports]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaginatedErrorReports copyWith({
    List<_i2.ErrorReport>? items,
    _i3.AdminPaginationInfo? pagination,
  }) {
    return PaginatedErrorReports(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      pagination: pagination ?? this.pagination.copyWith(),
    );
  }
}
