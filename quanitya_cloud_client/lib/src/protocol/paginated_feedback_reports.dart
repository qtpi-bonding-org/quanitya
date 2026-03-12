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
import 'feedback_report.dart' as _i2;
import 'admin_pagination_info.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i4;

abstract class PaginatedFeedbackReports implements _i1.SerializableModel {
  PaginatedFeedbackReports._({
    required this.items,
    required this.pagination,
  });

  factory PaginatedFeedbackReports({
    required List<_i2.FeedbackReport> items,
    required _i3.AdminPaginationInfo pagination,
  }) = _PaginatedFeedbackReportsImpl;

  factory PaginatedFeedbackReports.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PaginatedFeedbackReports(
      items: _i4.Protocol().deserialize<List<_i2.FeedbackReport>>(
        jsonSerialization['items'],
      ),
      pagination: _i4.Protocol().deserialize<_i3.AdminPaginationInfo>(
        jsonSerialization['pagination'],
      ),
    );
  }

  List<_i2.FeedbackReport> items;

  _i3.AdminPaginationInfo pagination;

  /// Returns a shallow copy of this [PaginatedFeedbackReports]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaginatedFeedbackReports copyWith({
    List<_i2.FeedbackReport>? items,
    _i3.AdminPaginationInfo? pagination,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaginatedFeedbackReports',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PaginatedFeedbackReportsImpl extends PaginatedFeedbackReports {
  _PaginatedFeedbackReportsImpl({
    required List<_i2.FeedbackReport> items,
    required _i3.AdminPaginationInfo pagination,
  }) : super._(
         items: items,
         pagination: pagination,
       );

  /// Returns a shallow copy of this [PaginatedFeedbackReports]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaginatedFeedbackReports copyWith({
    List<_i2.FeedbackReport>? items,
    _i3.AdminPaginationInfo? pagination,
  }) {
    return PaginatedFeedbackReports(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      pagination: pagination ?? this.pagination.copyWith(),
    );
  }
}
