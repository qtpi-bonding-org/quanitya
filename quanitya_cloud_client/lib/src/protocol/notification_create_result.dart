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
import 'package:quanitya_cloud_client/src/protocol/protocol.dart' as _i2;

abstract class NotificationCreateResult implements _i1.SerializableModel {
  NotificationCreateResult._({
    required this.notificationIds,
    required this.message,
  });

  factory NotificationCreateResult({
    required List<String> notificationIds,
    required String message,
  }) = _NotificationCreateResultImpl;

  factory NotificationCreateResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return NotificationCreateResult(
      notificationIds: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['notificationIds'],
      ),
      message: jsonSerialization['message'] as String,
    );
  }

  List<String> notificationIds;

  String message;

  /// Returns a shallow copy of this [NotificationCreateResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationCreateResult copyWith({
    List<String>? notificationIds,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationCreateResult',
      'notificationIds': notificationIds.toJson(),
      'message': message,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NotificationCreateResultImpl extends NotificationCreateResult {
  _NotificationCreateResultImpl({
    required List<String> notificationIds,
    required String message,
  }) : super._(
         notificationIds: notificationIds,
         message: message,
       );

  /// Returns a shallow copy of this [NotificationCreateResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationCreateResult copyWith({
    List<String>? notificationIds,
    String? message,
  }) {
    return NotificationCreateResult(
      notificationIds:
          notificationIds ?? this.notificationIds.map((e0) => e0).toList(),
      message: message ?? this.message,
    );
  }
}
