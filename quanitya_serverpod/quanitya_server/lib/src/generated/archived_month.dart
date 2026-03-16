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
import 'encrypted_entry.dart' as _i2;
import 'encrypted_template.dart' as _i3;
import 'encrypted_schedule.dart' as _i4;
import 'encrypted_analysis_script.dart' as _i5;
import 'package:quanitya_server/src/generated/protocol.dart' as _i6;

abstract class ArchivedMonth
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ArchivedMonth._({
    required this.userId,
    required this.year,
    required this.month,
    required this.entries,
    required this.templates,
    required this.schedules,
    required this.analysisScripts,
    required this.archivedAt,
    required this.version,
  });

  factory ArchivedMonth({
    required String userId,
    required int year,
    required int month,
    required List<_i2.EncryptedEntry> entries,
    required List<_i3.EncryptedTemplate> templates,
    required List<_i4.EncryptedSchedule> schedules,
    required List<_i5.EncryptedAnalysisScript> analysisScripts,
    required DateTime archivedAt,
    required String version,
  }) = _ArchivedMonthImpl;

  factory ArchivedMonth.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArchivedMonth(
      userId: jsonSerialization['userId'] as String,
      year: jsonSerialization['year'] as int,
      month: jsonSerialization['month'] as int,
      entries: _i6.Protocol().deserialize<List<_i2.EncryptedEntry>>(
        jsonSerialization['entries'],
      ),
      templates: _i6.Protocol().deserialize<List<_i3.EncryptedTemplate>>(
        jsonSerialization['templates'],
      ),
      schedules: _i6.Protocol().deserialize<List<_i4.EncryptedSchedule>>(
        jsonSerialization['schedules'],
      ),
      analysisScripts: _i6.Protocol()
          .deserialize<List<_i5.EncryptedAnalysisScript>>(
            jsonSerialization['analysisScripts'],
          ),
      archivedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['archivedAt'],
      ),
      version: jsonSerialization['version'] as String,
    );
  }

  String userId;

  int year;

  int month;

  List<_i2.EncryptedEntry> entries;

  List<_i3.EncryptedTemplate> templates;

  List<_i4.EncryptedSchedule> schedules;

  List<_i5.EncryptedAnalysisScript> analysisScripts;

  DateTime archivedAt;

  String version;

  /// Returns a shallow copy of this [ArchivedMonth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchivedMonth copyWith({
    String? userId,
    int? year,
    int? month,
    List<_i2.EncryptedEntry>? entries,
    List<_i3.EncryptedTemplate>? templates,
    List<_i4.EncryptedSchedule>? schedules,
    List<_i5.EncryptedAnalysisScript>? analysisScripts,
    DateTime? archivedAt,
    String? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'quanitya.ArchivedMonth',
      'userId': userId,
      'year': year,
      'month': month,
      'entries': entries.toJson(valueToJson: (v) => v.toJson()),
      'templates': templates.toJson(valueToJson: (v) => v.toJson()),
      'schedules': schedules.toJson(valueToJson: (v) => v.toJson()),
      'analysisScripts': analysisScripts.toJson(valueToJson: (v) => v.toJson()),
      'archivedAt': archivedAt.toJson(),
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'quanitya.ArchivedMonth',
      'userId': userId,
      'year': year,
      'month': month,
      'entries': entries.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'templates': templates.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'schedules': schedules.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'analysisScripts': analysisScripts.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'archivedAt': archivedAt.toJson(),
      'version': version,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ArchivedMonthImpl extends ArchivedMonth {
  _ArchivedMonthImpl({
    required String userId,
    required int year,
    required int month,
    required List<_i2.EncryptedEntry> entries,
    required List<_i3.EncryptedTemplate> templates,
    required List<_i4.EncryptedSchedule> schedules,
    required List<_i5.EncryptedAnalysisScript> analysisScripts,
    required DateTime archivedAt,
    required String version,
  }) : super._(
         userId: userId,
         year: year,
         month: month,
         entries: entries,
         templates: templates,
         schedules: schedules,
         analysisScripts: analysisScripts,
         archivedAt: archivedAt,
         version: version,
       );

  /// Returns a shallow copy of this [ArchivedMonth]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchivedMonth copyWith({
    String? userId,
    int? year,
    int? month,
    List<_i2.EncryptedEntry>? entries,
    List<_i3.EncryptedTemplate>? templates,
    List<_i4.EncryptedSchedule>? schedules,
    List<_i5.EncryptedAnalysisScript>? analysisScripts,
    DateTime? archivedAt,
    String? version,
  }) {
    return ArchivedMonth(
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      entries: entries ?? this.entries.map((e0) => e0.copyWith()).toList(),
      templates:
          templates ?? this.templates.map((e0) => e0.copyWith()).toList(),
      schedules:
          schedules ?? this.schedules.map((e0) => e0.copyWith()).toList(),
      analysisScripts:
          analysisScripts ??
          this.analysisScripts.map((e0) => e0.copyWith()).toList(),
      archivedAt: archivedAt ?? this.archivedAt,
      version: version ?? this.version,
    );
  }
}
