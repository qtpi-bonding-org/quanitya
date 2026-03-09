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

abstract class AdminSigningKey implements _i1.SerializableModel {
  AdminSigningKey._({
    this.id,
    required this.publicKeyHex,
    required this.roleName,
    required this.description,
    required this.createdAt,
    this.lastUsedAt,
    bool? isActive,
  }) : isActive = isActive ?? true;

  factory AdminSigningKey({
    int? id,
    required String publicKeyHex,
    required String roleName,
    required String description,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) = _AdminSigningKeyImpl;

  factory AdminSigningKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminSigningKey(
      id: jsonSerialization['id'] as int?,
      publicKeyHex: jsonSerialization['publicKeyHex'] as String,
      roleName: jsonSerialization['roleName'] as String,
      description: jsonSerialization['description'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String publicKeyHex;

  String roleName;

  String description;

  DateTime createdAt;

  DateTime? lastUsedAt;

  bool isActive;

  /// Returns a shallow copy of this [AdminSigningKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminSigningKey copyWith({
    int? id,
    String? publicKeyHex,
    String? roleName,
    String? description,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminSigningKey',
      if (id != null) 'id': id,
      'publicKeyHex': publicKeyHex,
      'roleName': roleName,
      'description': description,
      'createdAt': createdAt.toJson(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      'isActive': isActive,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminSigningKeyImpl extends AdminSigningKey {
  _AdminSigningKeyImpl({
    int? id,
    required String publicKeyHex,
    required String roleName,
    required String description,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) : super._(
         id: id,
         publicKeyHex: publicKeyHex,
         roleName: roleName,
         description: description,
         createdAt: createdAt,
         lastUsedAt: lastUsedAt,
         isActive: isActive,
       );

  /// Returns a shallow copy of this [AdminSigningKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminSigningKey copyWith({
    Object? id = _Undefined,
    String? publicKeyHex,
    String? roleName,
    String? description,
    DateTime? createdAt,
    Object? lastUsedAt = _Undefined,
    bool? isActive,
  }) {
    return AdminSigningKey(
      id: id is int? ? id : this.id,
      publicKeyHex: publicKeyHex ?? this.publicKeyHex,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt is DateTime? ? lastUsedAt : this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
