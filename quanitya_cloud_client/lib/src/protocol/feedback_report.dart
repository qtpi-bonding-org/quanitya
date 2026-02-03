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

abstract class FeedbackReport implements _i1.SerializableModel {
  FeedbackReport._({
    this.id,
    required this.feedbackText,
    required this.feedbackType,
    required this.submittedAt,
    this.metadata,
  });

  factory FeedbackReport({
    int? id,
    required String feedbackText,
    required String feedbackType,
    required DateTime submittedAt,
    String? metadata,
  }) = _FeedbackReportImpl;

  factory FeedbackReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return FeedbackReport(
      id: jsonSerialization['id'] as int?,
      feedbackText: jsonSerialization['feedbackText'] as String,
      feedbackType: jsonSerialization['feedbackType'] as String,
      submittedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['submittedAt'],
      ),
      metadata: jsonSerialization['metadata'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String feedbackText;

  String feedbackType;

  DateTime submittedAt;

  String? metadata;

  /// Returns a shallow copy of this [FeedbackReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FeedbackReport copyWith({
    int? id,
    String? feedbackText,
    String? feedbackType,
    DateTime? submittedAt,
    String? metadata,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeedbackReport',
      if (id != null) 'id': id,
      'feedbackText': feedbackText,
      'feedbackType': feedbackType,
      'submittedAt': submittedAt.toJson(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FeedbackReportImpl extends FeedbackReport {
  _FeedbackReportImpl({
    int? id,
    required String feedbackText,
    required String feedbackType,
    required DateTime submittedAt,
    String? metadata,
  }) : super._(
         id: id,
         feedbackText: feedbackText,
         feedbackType: feedbackType,
         submittedAt: submittedAt,
         metadata: metadata,
       );

  /// Returns a shallow copy of this [FeedbackReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FeedbackReport copyWith({
    Object? id = _Undefined,
    String? feedbackText,
    String? feedbackType,
    DateTime? submittedAt,
    Object? metadata = _Undefined,
  }) {
    return FeedbackReport(
      id: id is int? ? id : this.id,
      feedbackText: feedbackText ?? this.feedbackText,
      feedbackType: feedbackType ?? this.feedbackType,
      submittedAt: submittedAt ?? this.submittedAt,
      metadata: metadata is String? ? metadata : this.metadata,
    );
  }
}
