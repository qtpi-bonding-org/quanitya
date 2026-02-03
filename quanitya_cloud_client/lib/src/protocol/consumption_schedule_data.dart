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

abstract class ConsumptionScheduleData implements _i1.SerializableModel {
  ConsumptionScheduleData._({
    this.id,
    required this.scheduledAt,
    this.lastRun,
  });

  factory ConsumptionScheduleData({
    int? id,
    required DateTime scheduledAt,
    DateTime? lastRun,
  }) = _ConsumptionScheduleDataImpl;

  factory ConsumptionScheduleData.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConsumptionScheduleData(
      id: jsonSerialization['id'] as int?,
      scheduledAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['scheduledAt'],
      ),
      lastRun: jsonSerialization['lastRun'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastRun']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  DateTime scheduledAt;

  DateTime? lastRun;

  /// Returns a shallow copy of this [ConsumptionScheduleData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConsumptionScheduleData copyWith({
    int? id,
    DateTime? scheduledAt,
    DateTime? lastRun,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConsumptionScheduleData',
      if (id != null) 'id': id,
      'scheduledAt': scheduledAt.toJson(),
      if (lastRun != null) 'lastRun': lastRun?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConsumptionScheduleDataImpl extends ConsumptionScheduleData {
  _ConsumptionScheduleDataImpl({
    int? id,
    required DateTime scheduledAt,
    DateTime? lastRun,
  }) : super._(
         id: id,
         scheduledAt: scheduledAt,
         lastRun: lastRun,
       );

  /// Returns a shallow copy of this [ConsumptionScheduleData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConsumptionScheduleData copyWith({
    Object? id = _Undefined,
    DateTime? scheduledAt,
    Object? lastRun = _Undefined,
  }) {
    return ConsumptionScheduleData(
      id: id is int? ? id : this.id,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      lastRun: lastRun is DateTime? ? lastRun : this.lastRun,
    );
  }
}
