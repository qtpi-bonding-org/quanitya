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

abstract class AnalyticsEvent implements _i1.SerializableModel {
  AnalyticsEvent._({
    this.id,
    required this.eventName,
    required this.clientTimestamp,
    required this.serverReceivedAt,
    this.platform,
    this.props,
  });

  factory AnalyticsEvent({
    int? id,
    required String eventName,
    required DateTime clientTimestamp,
    required DateTime serverReceivedAt,
    String? platform,
    String? props,
  }) = _AnalyticsEventImpl;

  factory AnalyticsEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return AnalyticsEvent(
      id: jsonSerialization['id'] as int?,
      eventName: jsonSerialization['eventName'] as String,
      clientTimestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['clientTimestamp'],
      ),
      serverReceivedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverReceivedAt'],
      ),
      platform: jsonSerialization['platform'] as String?,
      props: jsonSerialization['props'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String eventName;

  DateTime clientTimestamp;

  DateTime serverReceivedAt;

  String? platform;

  String? props;

  /// Returns a shallow copy of this [AnalyticsEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AnalyticsEvent copyWith({
    int? id,
    String? eventName,
    DateTime? clientTimestamp,
    DateTime? serverReceivedAt,
    String? platform,
    String? props,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AnalyticsEvent',
      if (id != null) 'id': id,
      'eventName': eventName,
      'clientTimestamp': clientTimestamp.toJson(),
      'serverReceivedAt': serverReceivedAt.toJson(),
      if (platform != null) 'platform': platform,
      if (props != null) 'props': props,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AnalyticsEventImpl extends AnalyticsEvent {
  _AnalyticsEventImpl({
    int? id,
    required String eventName,
    required DateTime clientTimestamp,
    required DateTime serverReceivedAt,
    String? platform,
    String? props,
  }) : super._(
         id: id,
         eventName: eventName,
         clientTimestamp: clientTimestamp,
         serverReceivedAt: serverReceivedAt,
         platform: platform,
         props: props,
       );

  /// Returns a shallow copy of this [AnalyticsEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AnalyticsEvent copyWith({
    Object? id = _Undefined,
    String? eventName,
    DateTime? clientTimestamp,
    DateTime? serverReceivedAt,
    Object? platform = _Undefined,
    Object? props = _Undefined,
  }) {
    return AnalyticsEvent(
      id: id is int? ? id : this.id,
      eventName: eventName ?? this.eventName,
      clientTimestamp: clientTimestamp ?? this.clientTimestamp,
      serverReceivedAt: serverReceivedAt ?? this.serverReceivedAt,
      platform: platform is String? ? platform : this.platform,
      props: props is String? ? props : this.props,
    );
  }
}
