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

abstract class NotificationStatistics implements _i1.SerializableModel {
  NotificationStatistics._({
    required this.total,
    required this.marked,
    required this.unmarked,
  });

  factory NotificationStatistics({
    required int total,
    required int marked,
    required int unmarked,
  }) = _NotificationStatisticsImpl;

  factory NotificationStatistics.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationStatistics(
      total: jsonSerialization['total'] as int,
      marked: jsonSerialization['marked'] as int,
      unmarked: jsonSerialization['unmarked'] as int,
    );
  }

  int total;

  int marked;

  int unmarked;

  /// Returns a shallow copy of this [NotificationStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationStatistics copyWith({
    int? total,
    int? marked,
    int? unmarked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationStatistics',
      'total': total,
      'marked': marked,
      'unmarked': unmarked,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NotificationStatisticsImpl extends NotificationStatistics {
  _NotificationStatisticsImpl({
    required int total,
    required int marked,
    required int unmarked,
  }) : super._(
         total: total,
         marked: marked,
         unmarked: unmarked,
       );

  /// Returns a shallow copy of this [NotificationStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationStatistics copyWith({
    int? total,
    int? marked,
    int? unmarked,
  }) {
    return NotificationStatistics(
      total: total ?? this.total,
      marked: marked ?? this.marked,
      unmarked: unmarked ?? this.unmarked,
    );
  }
}
