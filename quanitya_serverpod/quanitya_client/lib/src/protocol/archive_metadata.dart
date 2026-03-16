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
import 'archive_month_info.dart' as _i2;
import 'package:quanitya_client/src/protocol/protocol.dart' as _i3;

abstract class ArchiveMetadata implements _i1.SerializableModel {
  ArchiveMetadata._({
    required this.userId,
    required this.availableMonths,
    required this.totalArchives,
    this.oldestArchive,
    this.newestArchive,
  });

  factory ArchiveMetadata({
    required String userId,
    required List<_i2.ArchiveMonthInfo> availableMonths,
    required int totalArchives,
    DateTime? oldestArchive,
    DateTime? newestArchive,
  }) = _ArchiveMetadataImpl;

  factory ArchiveMetadata.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArchiveMetadata(
      userId: jsonSerialization['userId'] as String,
      availableMonths: _i3.Protocol().deserialize<List<_i2.ArchiveMonthInfo>>(
        jsonSerialization['availableMonths'],
      ),
      totalArchives: jsonSerialization['totalArchives'] as int,
      oldestArchive: jsonSerialization['oldestArchive'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['oldestArchive'],
            ),
      newestArchive: jsonSerialization['newestArchive'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['newestArchive'],
            ),
    );
  }

  String userId;

  List<_i2.ArchiveMonthInfo> availableMonths;

  int totalArchives;

  DateTime? oldestArchive;

  DateTime? newestArchive;

  /// Returns a shallow copy of this [ArchiveMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchiveMetadata copyWith({
    String? userId,
    List<_i2.ArchiveMonthInfo>? availableMonths,
    int? totalArchives,
    DateTime? oldestArchive,
    DateTime? newestArchive,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.ArchiveMetadata',
      'userId': userId,
      'availableMonths': availableMonths.toJson(valueToJson: (v) => v.toJson()),
      'totalArchives': totalArchives,
      if (oldestArchive != null) 'oldestArchive': oldestArchive?.toJson(),
      if (newestArchive != null) 'newestArchive': newestArchive?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ArchiveMetadataImpl extends ArchiveMetadata {
  _ArchiveMetadataImpl({
    required String userId,
    required List<_i2.ArchiveMonthInfo> availableMonths,
    required int totalArchives,
    DateTime? oldestArchive,
    DateTime? newestArchive,
  }) : super._(
         userId: userId,
         availableMonths: availableMonths,
         totalArchives: totalArchives,
         oldestArchive: oldestArchive,
         newestArchive: newestArchive,
       );

  /// Returns a shallow copy of this [ArchiveMetadata]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchiveMetadata copyWith({
    String? userId,
    List<_i2.ArchiveMonthInfo>? availableMonths,
    int? totalArchives,
    Object? oldestArchive = _Undefined,
    Object? newestArchive = _Undefined,
  }) {
    return ArchiveMetadata(
      userId: userId ?? this.userId,
      availableMonths:
          availableMonths ??
          this.availableMonths.map((e0) => e0.copyWith()).toList(),
      totalArchives: totalArchives ?? this.totalArchives,
      oldestArchive: oldestArchive is DateTime?
          ? oldestArchive
          : this.oldestArchive,
      newestArchive: newestArchive is DateTime?
          ? newestArchive
          : this.newestArchive,
    );
  }
}
