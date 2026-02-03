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

abstract class ArchiveMonthInfo implements _i1.SerializableModel {
  ArchiveMonthInfo._({
    required this.year,
    required this.month,
    required this.archiveKey,
    this.uploadedAt,
  });

  factory ArchiveMonthInfo({
    required int year,
    required int month,
    required String archiveKey,
    String? uploadedAt,
  }) = _ArchiveMonthInfoImpl;

  factory ArchiveMonthInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArchiveMonthInfo(
      year: jsonSerialization['year'] as int,
      month: jsonSerialization['month'] as int,
      archiveKey: jsonSerialization['archiveKey'] as String,
      uploadedAt: jsonSerialization['uploadedAt'] as String?,
    );
  }

  int year;

  int month;

  String archiveKey;

  String? uploadedAt;

  /// Returns a shallow copy of this [ArchiveMonthInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchiveMonthInfo copyWith({
    int? year,
    int? month,
    String? archiveKey,
    String? uploadedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.ArchiveMonthInfo',
      'year': year,
      'month': month,
      'archiveKey': archiveKey,
      if (uploadedAt != null) 'uploadedAt': uploadedAt,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ArchiveMonthInfoImpl extends ArchiveMonthInfo {
  _ArchiveMonthInfoImpl({
    required int year,
    required int month,
    required String archiveKey,
    String? uploadedAt,
  }) : super._(
         year: year,
         month: month,
         archiveKey: archiveKey,
         uploadedAt: uploadedAt,
       );

  /// Returns a shallow copy of this [ArchiveMonthInfo]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchiveMonthInfo copyWith({
    int? year,
    int? month,
    String? archiveKey,
    Object? uploadedAt = _Undefined,
  }) {
    return ArchiveMonthInfo(
      year: year ?? this.year,
      month: month ?? this.month,
      archiveKey: archiveKey ?? this.archiveKey,
      uploadedAt: uploadedAt is String? ? uploadedAt : this.uploadedAt,
    );
  }
}
