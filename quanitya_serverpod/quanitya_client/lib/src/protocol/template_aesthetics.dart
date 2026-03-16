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

abstract class TemplateAesthetics implements _i1.SerializableModel {
  TemplateAesthetics._({
    _i1.UuidValue? id,
    required this.accountUuid,
    required this.templateId,
    this.themeName,
    this.icon,
    this.emoji,
    this.paletteJson,
    this.fontConfigJson,
    this.colorMappingsJson,
    DateTime? updatedAt,
  }) : id = id ?? const _i1.Uuid().v4obj(),
       updatedAt = updatedAt ?? DateTime.now();

  factory TemplateAesthetics({
    _i1.UuidValue? id,
    required String accountUuid,
    required String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  }) = _TemplateAestheticsImpl;

  factory TemplateAesthetics.fromJson(Map<String, dynamic> jsonSerialization) {
    return TemplateAesthetics(
      id: jsonSerialization['id'] == null
          ? null
          : _i1.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      accountUuid: jsonSerialization['accountUuid'] as String,
      templateId: jsonSerialization['templateId'] as String,
      themeName: jsonSerialization['themeName'] as String?,
      icon: jsonSerialization['icon'] as String?,
      emoji: jsonSerialization['emoji'] as String?,
      paletteJson: jsonSerialization['paletteJson'] as String?,
      fontConfigJson: jsonSerialization['fontConfigJson'] as String?,
      colorMappingsJson: jsonSerialization['colorMappingsJson'] as String?,
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The id of the object.
  _i1.UuidValue id;

  String accountUuid;

  String templateId;

  String? themeName;

  String? icon;

  String? emoji;

  String? paletteJson;

  String? fontConfigJson;

  String? colorMappingsJson;

  DateTime updatedAt;

  /// Returns a shallow copy of this [TemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TemplateAesthetics copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.TemplateAesthetics',
      'id': id.toJson(),
      'accountUuid': accountUuid,
      'templateId': templateId,
      if (themeName != null) 'themeName': themeName,
      if (icon != null) 'icon': icon,
      if (emoji != null) 'emoji': emoji,
      if (paletteJson != null) 'paletteJson': paletteJson,
      if (fontConfigJson != null) 'fontConfigJson': fontConfigJson,
      if (colorMappingsJson != null) 'colorMappingsJson': colorMappingsJson,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TemplateAestheticsImpl extends TemplateAesthetics {
  _TemplateAestheticsImpl({
    _i1.UuidValue? id,
    required String accountUuid,
    required String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         accountUuid: accountUuid,
         templateId: templateId,
         themeName: themeName,
         icon: icon,
         emoji: emoji,
         paletteJson: paletteJson,
         fontConfigJson: fontConfigJson,
         colorMappingsJson: colorMappingsJson,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TemplateAesthetics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TemplateAesthetics copyWith({
    _i1.UuidValue? id,
    String? accountUuid,
    String? templateId,
    Object? themeName = _Undefined,
    Object? icon = _Undefined,
    Object? emoji = _Undefined,
    Object? paletteJson = _Undefined,
    Object? fontConfigJson = _Undefined,
    Object? colorMappingsJson = _Undefined,
    DateTime? updatedAt,
  }) {
    return TemplateAesthetics(
      id: id ?? this.id,
      accountUuid: accountUuid ?? this.accountUuid,
      templateId: templateId ?? this.templateId,
      themeName: themeName is String? ? themeName : this.themeName,
      icon: icon is String? ? icon : this.icon,
      emoji: emoji is String? ? emoji : this.emoji,
      paletteJson: paletteJson is String? ? paletteJson : this.paletteJson,
      fontConfigJson: fontConfigJson is String?
          ? fontConfigJson
          : this.fontConfigJson,
      colorMappingsJson: colorMappingsJson is String?
          ? colorMappingsJson
          : this.colorMappingsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
