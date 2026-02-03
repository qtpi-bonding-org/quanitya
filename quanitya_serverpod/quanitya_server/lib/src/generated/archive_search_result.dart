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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class ArchiveSearchResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ArchiveSearchResult._({
    required this.year,
    required this.month,
    required this.archiveKey,
    required this.hasData,
  });

  factory ArchiveSearchResult({
    required int year,
    required int month,
    required String archiveKey,
    required bool hasData,
  }) = _ArchiveSearchResultImpl;

  factory ArchiveSearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArchiveSearchResult(
      year: jsonSerialization['year'] as int,
      month: jsonSerialization['month'] as int,
      archiveKey: jsonSerialization['archiveKey'] as String,
      hasData: jsonSerialization['hasData'] as bool,
    );
  }

  int year;

  int month;

  String archiveKey;

  bool hasData;

  /// Returns a shallow copy of this [ArchiveSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchiveSearchResult copyWith({
    int? year,
    int? month,
    String? archiveKey,
    bool? hasData,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.ArchiveSearchResult',
      'year': year,
      'month': month,
      'archiveKey': archiveKey,
      'hasData': hasData,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.ArchiveSearchResult',
      'year': year,
      'month': month,
      'archiveKey': archiveKey,
      'hasData': hasData,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ArchiveSearchResultImpl extends ArchiveSearchResult {
  _ArchiveSearchResultImpl({
    required int year,
    required int month,
    required String archiveKey,
    required bool hasData,
  }) : super._(
         year: year,
         month: month,
         archiveKey: archiveKey,
         hasData: hasData,
       );

  /// Returns a shallow copy of this [ArchiveSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchiveSearchResult copyWith({
    int? year,
    int? month,
    String? archiveKey,
    bool? hasData,
  }) {
    return ArchiveSearchResult(
      year: year ?? this.year,
      month: month ?? this.month,
      archiveKey: archiveKey ?? this.archiveKey,
      hasData: hasData ?? this.hasData,
    );
  }
}
