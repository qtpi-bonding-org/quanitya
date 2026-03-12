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
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i3;

abstract class AnalyticsStatistics implements _i1.SerializableModel {
  AnalyticsStatistics._({
    required this.totalEvents,
    required this.byEventName,
    required this.byPlatform,
    required this.recentEvents,
  });

  factory AnalyticsStatistics({
    required int totalEvents,
    required Map<String, int> byEventName,
    required Map<String, int> byPlatform,
    required List<_i2.AnalyticsEvent> recentEvents,
  }) = _AnalyticsStatisticsImpl;

  factory AnalyticsStatistics.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsStatistics(
      totalEvents: jsonSerialization['totalEvents'] as int,
      byEventName: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['byEventName'],
      ),
      byPlatform: _i3.Protocol().deserialize<Map<String, int>>(
        jsonSerialization['byPlatform'],
      ),
      recentEvents: _i3.Protocol().deserialize<List<_i2.AnalyticsEvent>>(
        jsonSerialization['recentEvents'],
      ),
    );
  }

  int totalEvents;

  Map<String, int> byEventName;

  Map<String, int> byPlatform;

  List<_i2.AnalyticsEvent> recentEvents;

  /// Returns a shallow copy of this [AnalyticsStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnalyticsStatistics copyWith({
    int? totalEvents,
    Map<String, int>? byEventName,
    Map<String, int>? byPlatform,
    List<_i2.AnalyticsEvent>? recentEvents,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsStatistics',
      'totalEvents': totalEvents,
      'byEventName': byEventName.toJson(),
      'byPlatform': byPlatform.toJson(),
      'recentEvents': recentEvents.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AnalyticsStatisticsImpl extends AnalyticsStatistics {
  _AnalyticsStatisticsImpl({
    required int totalEvents,
    required Map<String, int> byEventName,
    required Map<String, int> byPlatform,
    required List<_i2.AnalyticsEvent> recentEvents,
  }) : super._(
         totalEvents: totalEvents,
         byEventName: byEventName,
         byPlatform: byPlatform,
         recentEvents: recentEvents,
       );

  /// Returns a shallow copy of this [AnalyticsStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnalyticsStatistics copyWith({
    int? totalEvents,
    Map<String, int>? byEventName,
    Map<String, int>? byPlatform,
    List<_i2.AnalyticsEvent>? recentEvents,
  }) {
    return AnalyticsStatistics(
      totalEvents: totalEvents ?? this.totalEvents,
      byEventName:
          byEventName ??
          this.byEventName.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      byPlatform:
          byPlatform ??
          this.byPlatform.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      recentEvents:
          recentEvents ?? this.recentEvents.map((e0) => e0.copyWith()).toList(),
    );
  }
}
