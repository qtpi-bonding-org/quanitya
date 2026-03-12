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
import 'analytics_event.dart' as _i2;
import 'admin_pagination_info.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i4;

abstract class PaginatedAnalyticsEvents implements _i1.SerializableModel {
  PaginatedAnalyticsEvents._({
    required this.items,
    required this.pagination,
  });

  factory PaginatedAnalyticsEvents({
    required List<_i2.AnalyticsEvent> items,
    required _i3.AdminPaginationInfo pagination,
  }) = _PaginatedAnalyticsEventsImpl;

  factory PaginatedAnalyticsEvents.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PaginatedAnalyticsEvents(
      items: _i4.Protocol().deserialize<List<_i2.AnalyticsEvent>>(
        jsonSerialization['items'],
      ),
      pagination: _i4.Protocol().deserialize<_i3.AdminPaginationInfo>(
        jsonSerialization['pagination'],
      ),
    );
  }

  List<_i2.AnalyticsEvent> items;

  _i3.AdminPaginationInfo pagination;

  /// Returns a shallow copy of this [PaginatedAnalyticsEvents]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaginatedAnalyticsEvents copyWith({
    List<_i2.AnalyticsEvent>? items,
    _i3.AdminPaginationInfo? pagination,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaginatedAnalyticsEvents',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PaginatedAnalyticsEventsImpl extends PaginatedAnalyticsEvents {
  _PaginatedAnalyticsEventsImpl({
    required List<_i2.AnalyticsEvent> items,
    required _i3.AdminPaginationInfo pagination,
  }) : super._(
         items: items,
         pagination: pagination,
       );

  /// Returns a shallow copy of this [PaginatedAnalyticsEvents]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaginatedAnalyticsEvents copyWith({
    List<_i2.AnalyticsEvent>? items,
    _i3.AdminPaginationInfo? pagination,
  }) {
    return PaginatedAnalyticsEvents(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      pagination: pagination ?? this.pagination.copyWith(),
    );
  }
}
