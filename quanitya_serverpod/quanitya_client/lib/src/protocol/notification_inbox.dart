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

/// A notification message for a specific user
abstract class NotificationInbox implements _i1.SerializableModel {
  NotificationInbox._({
    this.id,
    required this.accountUuid,
    required this.title,
    required this.type,
    required this.createdAt,
    this.actionPayload,
  });

  factory NotificationInbox({
    int? id,
    required String accountUuid,
    required String title,
    required String type,
    required DateTime createdAt,
    String? actionPayload,
  }) = _NotificationInboxImpl;

  factory NotificationInbox.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationInbox(
      id: jsonSerialization['id'] as int?,
      accountUuid: jsonSerialization['accountUuid'] as String,
      title: jsonSerialization['title'] as String,
      type: jsonSerialization['type'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      actionPayload: jsonSerialization['actionPayload'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The account UUID of the user who should receive this notification
  String accountUuid;

  /// The title/message content of the notification
  String title;

  /// The type of notification (system, report, alert)
  String type;

  /// When the notification was created
  DateTime createdAt;

  /// Optional JSON payload for navigation or actions
  String? actionPayload;

  /// Returns a shallow copy of this [NotificationInbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationInbox copyWith({
    int? id,
    String? accountUuid,
    String? title,
    String? type,
    DateTime? createdAt,
    String? actionPayload,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.NotificationInbox',
      if (id != null) 'id': id,
      'accountUuid': accountUuid,
      'title': title,
      'type': type,
      'createdAt': createdAt.toJson(),
      if (actionPayload != null) 'actionPayload': actionPayload,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationInboxImpl extends NotificationInbox {
  _NotificationInboxImpl({
    int? id,
    required String accountUuid,
    required String title,
    required String type,
    required DateTime createdAt,
    String? actionPayload,
  }) : super._(
         id: id,
         accountUuid: accountUuid,
         title: title,
         type: type,
         createdAt: createdAt,
         actionPayload: actionPayload,
       );

  /// Returns a shallow copy of this [NotificationInbox]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationInbox copyWith({
    Object? id = _Undefined,
    String? accountUuid,
    String? title,
    String? type,
    DateTime? createdAt,
    Object? actionPayload = _Undefined,
  }) {
    return NotificationInbox(
      id: id is int? ? id : this.id,
      accountUuid: accountUuid ?? this.accountUuid,
      title: title ?? this.title,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      actionPayload: actionPayload is String?
          ? actionPayload
          : this.actionPayload,
    );
  }
}
