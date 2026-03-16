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

abstract class Notification implements _i1.SerializableModel {
  Notification._({
    this.id,
    this.accountUuid,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.actionUrl,
    this.actionLabel,
    this.markedAt,
    required this.updatedAt,
  });

  factory Notification({
    _i1.UuidValue? id,
    String? accountUuid,
    required String title,
    required String message,
    required String type,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? actionUrl,
    String? actionLabel,
    DateTime? markedAt,
    required DateTime updatedAt,
  }) = _NotificationImpl;

  factory Notification.fromJson(Map<String, dynamic> jsonSerialization) {
    return Notification(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountUuid: jsonSerialization['accountUuid'] as String?,
      title: jsonSerialization['title'] as String,
      message: jsonSerialization['message'] as String,
      type: jsonSerialization['type'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      actionUrl: jsonSerialization['actionUrl'] as String?,
      actionLabel: jsonSerialization['actionLabel'] as String?,
      markedAt: jsonSerialization['markedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['markedAt']),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  String? accountUuid;

  String title;

  String message;

  String type;

  DateTime createdAt;

  DateTime expiresAt;

  String? actionUrl;

  String? actionLabel;

  DateTime? markedAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Notification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Notification copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? actionUrl,
    String? actionLabel,
    DateTime? markedAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Notification',
      if (id != null) 'id': id?.toJson(),
      if (accountUuid != null) 'accountUuid': accountUuid,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (actionLabel != null) 'actionLabel': actionLabel,
      if (markedAt != null) 'markedAt': markedAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationImpl extends Notification {
  _NotificationImpl({
    _i1.UuidValue? id,
    String? accountUuid,
    required String title,
    required String message,
    required String type,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? actionUrl,
    String? actionLabel,
    DateTime? markedAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         accountUuid: accountUuid,
         title: title,
         message: message,
         type: type,
         createdAt: createdAt,
         expiresAt: expiresAt,
         actionUrl: actionUrl,
         actionLabel: actionLabel,
         markedAt: markedAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Notification]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Notification copyWith({
    Object? id = _Undefined,
    Object? accountUuid = _Undefined,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    Object? actionUrl = _Undefined,
    Object? actionLabel = _Undefined,
    Object? markedAt = _Undefined,
    DateTime? updatedAt,
  }) {
    return Notification(
      id: id is _i1.UuidValue? ? id : this.id,
      accountUuid: accountUuid is String? ? accountUuid : this.accountUuid,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      actionUrl: actionUrl is String? ? actionUrl : this.actionUrl,
      actionLabel: actionLabel is String? ? actionLabel : this.actionLabel,
      markedAt: markedAt is DateTime? ? markedAt : this.markedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
