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

abstract class EncryptedAnalysisScript implements _i1.SerializableModel {
  EncryptedAnalysisScript._({
    _i1.UuidValue? id,
    required this.accountUuid,
    required this.encryptedData,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory EncryptedAnalysisScript({
    _i1.UuidValue? id,
    required String accountUuid,
    required String encryptedData,
    DateTime? updatedAt,
  }) = _EncryptedAnalysisScriptImpl;

  factory EncryptedAnalysisScript.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return EncryptedAnalysisScript(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountUuid: jsonSerialization['accountUuid'] as String,
      encryptedData: jsonSerialization['encryptedData'] as String,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The id of the object.
  _i1.UuidValue id;

  String accountUuid;

  String encryptedData;

  DateTime updatedAt;

  /// Returns a shallow copy of this [EncryptedAnalysisScript]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EncryptedAnalysisScript copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? encryptedData,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.EncryptedAnalysisScript',
      'id': id.toJson(),
      'accountUuid': accountUuid,
      'encryptedData': encryptedData,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _EncryptedAnalysisScriptImpl extends EncryptedAnalysisScript {
  _EncryptedAnalysisScriptImpl({
    _i1.UuidValue? id,
    required String accountUuid,
    required String encryptedData,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountUuid: accountUuid,
         encryptedData: encryptedData,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [EncryptedAnalysisScript]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EncryptedAnalysisScript copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? encryptedData,
    DateTime? updatedAt,
  }) {
    return EncryptedAnalysisScript(
      id: id ?? this.id,
      accountUuid: accountUuid ?? this.accountUuid,
      encryptedData: encryptedData ?? this.encryptedData,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
