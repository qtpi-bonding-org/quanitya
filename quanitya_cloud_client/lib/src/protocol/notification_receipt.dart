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

abstract class NotificationReceipt implements _i1.SerializableModel {
  NotificationReceipt._({
    this.id,
    required this.notificationId,
    required this.accountUuid,
    required this.markedAt,
    required this.createdAt,
  });

  factory NotificationReceipt({
    _i1.UuidValue? id,
    required _i1.UuidValue notificationId,
    required String accountUuid,
    required DateTime markedAt,
    required DateTime createdAt,
  }) = _NotificationReceiptImpl;

  factory NotificationReceipt.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotificationReceipt(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      notificationId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['notificationId'],
      ),
      accountUuid: jsonSerialization['accountUuid'] as String,
      markedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['markedAt'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  _i1.UuidValue? id;

  _i1.UuidValue notificationId;

  String accountUuid;

  DateTime markedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [NotificationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotificationReceipt copyWith({
    _i1.UuidValue? id,
    _i1.UuidValue? notificationId,
    String? accountUuid,
    DateTime? markedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotificationReceipt',
      if (id != null) 'id': id?.toJson(),
      'notificationId': notificationId.toJson(),
      'accountUuid': accountUuid,
      'markedAt': markedAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NotificationReceiptImpl extends NotificationReceipt {
  _NotificationReceiptImpl({
    _i1.UuidValue? id,
    required _i1.UuidValue notificationId,
    required String accountUuid,
    required DateTime markedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         notificationId: notificationId,
         accountUuid: accountUuid,
         markedAt: markedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [NotificationReceipt]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotificationReceipt copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? notificationId,
    String? accountUuid,
    DateTime? markedAt,
    DateTime? createdAt,
  }) {
    return NotificationReceipt(
      id: id is _i1.UuidValue? ? id : this.id,
      notificationId: notificationId ?? this.notificationId,
      accountUuid: accountUuid ?? this.accountUuid,
      markedAt: markedAt ?? this.markedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
